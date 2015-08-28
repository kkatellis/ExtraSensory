'''
classifiers.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. June 2015.
'''

import os;
import os.path;
import numpy;
import pickle;
import sklearn.linear_model;
import traceback;
import multiprocessing;
import time;

import pdb;

def classify(x,classifier):
    if classifier['model_params']['standardize_features']:
        # Standardize the vector:
        x       = standardize_features(x,classifier['mean_vec'],classifier['std_vec']);
        pass;

    x           = apply_missing_values_policy(x,classifier['model_params']['missing_value_policy']);
    
    if classifier['model_params']['model_type'] == 'logit':
        (bin_vec,prob_vec)  = classify__logit(x,classifier);
        pass;
    elif classifier['model_params']['model_type'] == 'multilayer_logit':
        (bin_vec,prob_vec)  = classify__multilayer_logit(x,classifier);
        pass;
    else:
        (bin_vec,prob_vec)  = (None,None);
        pass;
    
    return (bin_vec,prob_vec);

def train_classifier(X,instances_labels,label_names,model_params):
    if 'model_type' not in model_params:
        return None;

    n_samples   = X.shape[0];
    n_samples2  = instances_labels.shape[0];
    if (n_samples2 != n_samples):
        raise Exception('Cant train classifier. Got %d instances but %d labels' % (n_samples,n_sampmles2));

    classifier  = {'model_params':model_params,'label_names':label_names};
    if model_params['standardize_features']:
        # Standardize (and save the standardization parameters):
        X_old                   = numpy.copy(X);
        (X,mean_vec,std_vec)    = estimate_standardization(X);
        classifier['mean_vec']  = mean_vec;
        classifier['std_vec']   = std_vec;
        pass;

    X           = apply_missing_values_policy(X,model_params['missing_value_policy']);

    train_data  = {'X_old':X_old,'X':X,'model_params':model_params};
    train_file  = os.path.join(model_params['train_dir'],'treated_train_data.pickle');
    fid         = file(train_file,'wb');
    pickle.dump(train_data,fid);
    fid.close();

    if model_params['model_type'] == 'logit':
        classifier  = train_classifier__logit(X,instances_labels,label_names,classifier);
        pass;
    elif model_params['model_type'] == 'multilayer_logit':
        classifier  = train_classifier__multilayer_logit(X,instances_labels,label_names,classifier);
        pass;
    else:
        classifier  = None;
        pass;
    
    return classifier;

def semirandomly_partition_examples(instances_bin_labels,test_set_portion):
    n_total         = len(instances_bin_labels);
    pos_inds        = numpy.where(instances_bin_labels)[0];
    n_pos           = len(pos_inds);
    neg_inds        = numpy.where(numpy.logical_not(instances_bin_labels))[0];
    n_neg           = len(neg_inds);

    n_test_pos      = (int)(numpy.ceil(n_pos * test_set_portion));
    n_test_neg      = (int)(numpy.ceil(n_neg * test_set_portion));

    # Shuffle the example indices:
    numpy.random.shuffle(pos_inds);
    numpy.random.shuffle(neg_inds);

    # Partition:
    test_pos_inds   = pos_inds[:n_test_pos];
    train_pos_inds  = pos_inds[n_test_pos:];
    test_neg_inds   = neg_inds[:n_test_neg];
    train_neg_inds  = neg_inds[n_test_neg:];

    test_inds       = numpy.concatenate((test_pos_inds,test_neg_inds));
    train_inds      = numpy.concatenate((train_pos_inds,train_neg_inds));

    return (train_inds,test_inds);

'''
Get performance scores for binary classification.

Input:
y_gt: either single array (n_samples) or nd-array (n_samples x n_classes).
    Holding the ground truth binary labels of each instance (and possibly for multiple classes).
y_hat: either single array (n_samples) or nd-array (n_samples x n_classes).
    Holding the machine's binary classification result for each instance.

Output:
tpr: scalar (if input had single class) or array (n_classes). True Positive Rate:
    portion of correctly classified examples out of the ground truth positives.
tnr: scalar (if input had single class) or array (n_classes). True Negative Rate:
    portion of correctly classified examples out of the ground truth negatives.
accuracy: scalar (if input had single class) or array (n_classes). Classification accuracy:
    portion of correctly classified examples in the entire set.
'''
def binary_classification_success_rates(y_gt,y_hat):
    n_pos_gt        = numpy.sum(y_gt,axis=0);
    not_y_gt        = numpy.logical_not(y_gt);
    n_neg_gt        = numpy.sum(not_y_gt,axis=0);

    # Count hits and correct rejections:
    tp              = numpy.sum(y_gt * y_hat,axis=0).astype(float);
    tn              = numpy.sum(not_y_gt * numpy.logical_not(y_hat),axis=0).astype(float);

    if (len(y_gt.shape) > 1):
        tpr         = numpy.where(n_pos_gt > 0,tp / n_pos_gt, numpy.nan);
        tnr         = numpy.where(n_neg_gt > 0,tn / n_neg_gt, numpy.nan);
        pass;
    else:
        tpr         = tp / n_pos_gt;
        tnr         = tn / n_neg_gt;
        pass;

    accuracy        = numpy.mean(y_gt == y_hat,axis=0);

    return (tpr,tnr,accuracy);

'''
Get performance scores for soft classification (class probabilities).

Input:
y_gt: nd-array (n_samples x n_classes).
    Holding the ground truth binary labels of each instance for each classes.
y_prob: nd-array (n_samples x n_classes).
    Holding the machine's real classification probability results for each instance.

Output:
soft_tpr: array (n_classes). Soft True Positive Rate:
    average probability given by the machine to the ground truth positives.
soft_tnr: array (n_classes). Soft True Negative Rate:
    average [1-probability] (=probability of machine declaring "negative") given by the machine to the ground truth negatives.
soft_accuracy: array (n_classes). Soft classification accuracy:
    average over the entire set of the given probability,
    while considering the [1-probability] for the ground truth negatives.
'''
def soft_classification_success_rates(y_gt,y_prob):
    n_pos_gt        = numpy.sum(y_gt,axis=0);
    not_y_gt        = numpy.logical_not(y_gt);
    n_neg_gt        = numpy.sum(not_y_gt,axis=0);

    # Classification of the gt positives:
    prob_for_pos    = y_gt * y_prob;
    sum_pos_probs   = numpy.sum(prob_for_pos,axis=0);
    soft_tpr        = numpy.where(n_pos_gt > 0,sum_pos_probs / n_pos_gt, numpy.nan);

    # Classification of the gt negatives:
    prob_for_neg    = not_y_gt * (1-y_prob);
    sum_neg_probs   = numpy.sum(prob_for_neg,axis=0);
    soft_tnr        = numpy.where(n_neg_gt > 0,sum_neg_probs / n_neg_gt, numpy.nan);

    # General soft accuracy (correlation):
    soft_accuracy   = numpy.mean(prob_for_pos + prob_for_neg, axis=0);
    return (soft_tpr,soft_tnr,soft_accuracy);
    
'''
Calculate label-ranking score for multiple instances.

Input:
Y_gt: (n_samples x n_labels) 2d array of binary values. The ground truth for each instance (each row):
    for each label is it relevant or not.
rank_mat (n_samples x n_labels) integer matrix. For each instance (row) the order of the ranked labels:
    e.g. rank_mat[2,0]=13 means that for instance 2, label 13 was ranked first (highest probability).

Output:
mp5: Preceision at top 5 ranked labels (mean over n_samples instances).
mr5: Recall at top 5 ranked labels (mean over n_samples instances).
mf5: F-score for p5 and r5 (mean over n_samples instances).
map: Average precision: average of precision values at all cutoffs where there's a true positive (mean over n_samples instances).
'''
def label_ranking_measures(Y_gt,rank_mat):
    n_samples           = Y_gt.shape[0];
    p5s                 = numpy.nan*numpy.ones(n_samples);
    r5s                 = numpy.nan*numpy.ones(n_samples);
    f5s                 = numpy.nan*numpy.ones(n_samples);
    aps                 = numpy.nan*numpy.ones(n_samples);

    for ii in range(n_samples):
        (p5,r5,f5,ap)   = label_ranking_measures_single_instance(Y_gt[ii,:],rank_mat[ii,:]);
        p5s[ii]         = p5;
        r5s[ii]         = r5;
        f5s[ii]         = f5;
        aps[ii]         = ap;
        pass;

    mp5                 = numpy.nanmean(p5s);
    mr5                 = numpy.nanmean(r5s);
    mf5                 = numpy.nanmean(f5s);
    map                 = numpy.nanmean(ap);
    
    return (mp5,mr5,mf5,map);

'''
Calculate label-ranking score for a single instance.

Input:
y_gt: (n_labels) 1d array of binary values. The ground truth for the instance:
    for each label is it relevant or not.
y_prob: (n_labels) 1d array of real values. The probability/affinity values produced by the classifier/regressor for each label.

Output:
p5: Preceision at top 5 ranked labels.
r5: Recall at top 5 ranked labels.
f5: F-score for p5 and r5.
ap: Average precision: average of precision values at all cutoffs where there's a true positive.
'''
def label_ranking_measures_single_instance(y_gt,rank_vec):
    n_labels            = y_gt.size;
    n_relevant          = numpy.sum(y_gt);

    # Order the ground truth labels according to the machine's provided ranking:    
    ranked_gt           = y_gt[rank_vec];

    # Evaluate the precision at every position in the ranking:
    true_positives      = numpy.cumsum(ranked_gt).astype(float);
    positives           = numpy.array(range(n_labels)) + 1.;
    precisions          = true_positives / positives;
    recalls             = true_positives / n_relevant;
    
    # Evaluate binary classification, in which we take the top 5 ranked labels:
    p5                  = precisions[4];
    r5                  = recalls[4];
    f5                  = (2.*p5*r5)/(p5+r5);

    # Now evaluate average precision:
    prec_when_relevant  = precisions * ranked_gt;
    ap                  = numpy.mean(prec_when_relevant);

    return (p5,r5,f5,ap);


'''
Rank the labels of each instance according to some affinity/probability measure.

Input:
Y_prob: (n_samples x n_labels) real matrix. The probability/affinity values for each instance-label pair.

Output:
rank_mat (n_samples x n_labels) integer matrix. For each instance (row) the order of the ranked labels:
    e.g. rank_mat[2,0]=13 means that for instance 2, label 13 was ranked first (highest probability).
'''
def rank_labels_for_each_instance(Y_prob):
    (n_samples,n_labels)= Y_prob.shape;
    rank_mat            = numpy.zeros((n_samples,n_labels),dtype=int);    

    for ii in range(n_samples):
        pairs           = enumerate(Y_prob[ii,:]);
        sorted_pairs    = sorted(pairs,key=lambda x: x[1],reverse=True);
        ind_rank        = [pair[0] for pair in sorted_pairs];
        rank_mat[ii,:]  = ind_rank;
        pass;

    return rank_mat;

'''
Create binary labels from per-instance label-ranking by selecting only the top labels for each instance.

Input:
rank_mat (n_samples x n_labels) integer matrix. For each instance (row) the order of the ranked labels:
    e.g. rank_mat[2,0]=13 means that for instance 2, label 13 was ranked first (highest probability).
how_many: positive integer. How many labels to annotate for each instance.

Output:
Y_top_bin: (n_samples x n_labels) binary. The selected labels for each instance marked with 1.
'''
def select_top_labels_per_instance(rank_mat,how_many):
    (n_samples,n_labels)= rank_mat.shape;
    Y_top_bin           = numpy.zeros((n_samples,n_labels),dtype=bool);

    for ii in range(n_samples):
        top                 = rank_mat[ii,:how_many];
        Y_top_bin[ii,top]   = 1;
        pass;

    return Y_top_bin;

'''
Ger performace scores for the quality of classification.

Input:
Y_gt: (n_samples x n_labels) binary. The ground truth labels.
Y_bin: (n_samples x n_labels) binary. The machine given binary labels.
Y_prob: (n_samples x n_labels) real. The machine given probability/affinity values.
label_names: list of n_labels strings. The names of the labels.
'''
def get_classification_scores(Y_gt,Y_bin,Y_prob,label_names):
    scores                              = get_classification_scores_helper(Y_gt,Y_bin,Y_prob);
    scores['n_samples']                 = Y_gt.shape[0];
    scores['label_names']               = label_names;

    n_samples                           = Y_gt.shape[0];
    ind_order                           = numpy.array(range(n_samples));
    numpy.random.shuffle(ind_order);
    Y_scrambled_gt                      = Y_gt[ind_order,:];
    random_chance_scores                = get_classification_scores_helper(Y_scrambled_gt,Y_bin,Y_prob);
    scores['random_chance']             = random_chance_scores;

    return scores;

'''
Ger performace scores for the quality of classification.

Input:
Y_gt: (n_samples x n_labels) binary. The ground truth labels.
Y_bin: (n_samples x n_labels) binary. The machine given binary labels.
Y_prob: (n_samples x n_labels) real. The machine given probability/affinity values.
'''
def get_classification_scores_helper(Y_gt,Y_bin,Y_prob):
    scores                              = {};
    # Analyze performance with the given machine binary labels:
    (naive_tprs,naive_tnrs,naive_accs)    = binary_classification_success_rates(\
        Y_gt,Y_bin);
    scores['naive_tprs']                = naive_tprs;
    scores['naive_tnrs']                = naive_tnrs;
    scores['naive_accs']                = naive_accs;

    rank_mat                            = rank_labels_for_each_instance(Y_prob);
    Y_top5_bin                          = select_top_labels_per_instance(rank_mat,5);

    # Analyze performance with the policy of selecting top-5 labels for each instance:
    (top5_tprs,top5_tnrs,top5_accs)    = binary_classification_success_rates(\
        Y_gt,Y_top5_bin);
    scores['top5_tprs']                 = top5_tprs;
    scores['top5_tnrs']                 = top5_tnrs;
    scores['top5_accs']                 = top5_accs;

    # Analyze the (averaged over instances) ranking-quality of labels for each instance:
    (mp5,mr5,mf5,map)                   = label_ranking_measures(Y_gt,rank_mat);
    scores['mp5']                       = mp5;
    scores['mr5']                       = mr5;
    scores['mf5']                       = mf5;
    scores['map']                       = map;
    
    return scores;


###########################################
### Helping functions:
#########################

'''
Get only the valid examples from a collection of examples,
meaning only the examples that don't have NaN in them.

Input:
feats: (n_examples x dim) The feature vectors of n_examples examples

Output:
valid_inds: list of indices of valid examples.
valid_examples: (n_valid x dim) The feature vectors of the valid examples.
'''
def get_valid_examples(feats):
    n_examples          = feats.shape[0];
    invalid             = numpy.where(numpy.isnan(feats));
    invalid_inds        = set(invalid[0]);

    valid_inds          = list(set(range(n_examples)).difference(invalid_inds));
    valid_examples      = feats[valid_inds,:];

    return (valid_inds,valid_examples);

'''
Apply some policy to handle missing values in each feature vector.

Input:
X: (N x din) matrix of N feature vectors. Values of NaN, inf or -inf are regarded as missing values.
policy: string. One of:
    'zero_imputation': replace every missing value with value of zero.
    'missing_indicators': replace every missing value with value of zero,
    and augment to the feature vector an indicator vector of the same dimension din,
    where each indicator has 1 if the corresponding feature is missing and 0 otherwise.

Output:
X: (N x dout) matrix of feature vectors.
    The feature vectors, after being handled with the selected policy,
    possibly now having a different dimension than the input feature vector.
'''
def apply_missing_values_policy(X,policy):
    is_missing          = numpy.logical_or(numpy.isnan(X),numpy.isinf(X));
    if policy == 'zero_imputation':
        X[is_missing]   = 0;
        pass;
    elif policy == 'missing_indicators':
        X[is_missing]   = 0;
        X               = numpy.concatenate((X,is_missing.astype(X.dtype)),axis=-1);
##        feature_vector              = numpy.concatenate((feature_vector,is_missing.astype(feature_vector.dtype)));
##        feature_vector              = numpy.reshape(feature_vector,(1,-1));
        pass;
    else:
        # Leave the feature vector as it is
        pass;

    return X;

def get_feature_dim(model_params):
    dim         = model_params['feature_dimension'];
    if model_params['missing_value_policy'] == 'missing_indicators':
        dim     *= 2;
        pass;

    return dim;

'''
Standardize the features by z-scoring.

Input:
X: (n x d) array of n feature vectors of dimension d.
mean_vec: d-array of pre-trained estimation of mean vector.
std_vec: d-array of pre-trained estimation of standard deviations.

Output:
Z: (n x d) array of the standardized features.
'''
def standardize_features(X,mean_vec,std_vec):
    # Avoid dividing by zero:
    epsilon         = 0.0000001;
    dividers_vec    = numpy.where(std_vec <= epsilon,1.,std_vec);

    Z               = (X-mean_vec) / dividers_vec;
    return Z;

'''
Estimate the standardization parameters (vector of means and vector of standard deviations),
and standardize the estimation features themselves.

Input:
X: (n x d) array of n feature vectors of dimension d.

Output:
Z: (n x d) array of the standardized feature vectors.
mean_vec: d-array of estimated mean values.
std_vec: d-array of estimated standard deviations.
'''
def estimate_standardization(X):
    mean_vec        = numpy.nanmean(X,axis=0);
    std_vec         = numpy.nanstd(X,axis=0);
    Z               = standardize_features(X,mean_vec,std_vec);

    return (Z,mean_vec,std_vec);

def get_feature_sensor_map(dummy_instance_features,sensors):
    sensor_ind      = numpy.zeros(0);
    for (si,sensor) in enumerate(sensors):
        feat        = dummy_instance_features[sensor];
        sensor_ind  = numpy.concatenate((sensor_ind,si*numpy.ones(len(feat),dtype=int)));
        pass;
    return sensor_ind;

def construct_feature_vector(instance_features,model_params):
    # Construct a single feature vector for this instance:
    x           = numpy.zeros(0);
    for sensor in model_params['sensors']:
        x       = numpy.concatenate((x,instance_features[sensor]));
        pass;
    x           = numpy.reshape(x,(1,-1));

    x           = apply_missing_values_policy(x,model_params['missing_value_policy']);
    
    return x;


###########################################
### Specific classifiers:
#########################

### Logistic regression (logit):    
def classify__logit(x,classifier):
    # Use the pre-trained models to predict:
    n_classes   = len(classifier['label_models']);
    prob_vec    = numpy.zeros(n_classes);
    if (numpy.sum(numpy.isnan(x)) <= 0):
        for ci in range(n_classes):
            single_model    = classifier['label_models'][ci];
            if (single_model != None):
                pos_ind         = single_model.classes_.tolist().index(1);
                prob_vec[ci]    = single_model.predict_proba(x)[0,pos_ind];
                pass;
            pass;
        pass;
    
    bin_vec     = prob_vec > 0.5;
    
    return (bin_vec,prob_vec);

def train_classifier__logit(X,instances_labels,label_names,classifier):
    n_classes           = len(label_names);
    train_dir           = classifier['model_params']['train_dir'];
    
    # Go over the labels classes and for each construct a binary classifier:
    in_Q                = multiprocessing.Queue();
    out_Q               = multiprocessing.Queue();
    label_models        = [None for ci in range(n_classes)];
    n_pos_per_label     = numpy.zeros(n_classes);
    n_neg_per_label     = numpy.zeros(n_classes);
    # Fill the process queue with tasks:
    for ci in range(n_classes):
        y       = instances_labels[:,ci].astype(int);
        in_Q.put((ci,label_names[ci],y,train_dir));
        pass;

    # Create the subprocesses:
    n_cores             = 16;
    for core_i in range(n_cores):
        P               = multiprocessing.Process(\
            target=feed_single_label_task_to_process__logit,\
            args=(in_Q,out_Q,X));
        P.start();
        pass;

    # Wait while the tasks are being performed:
    label_inds_left     = set(range(n_classes));
    while len(label_inds_left) > 0: #not out_Q.empty() or not in_Q.empty():
        if not out_Q.empty():
            # Get the results of a task:
            (class_i,label_name,single_model,npos,nneg) = out_Q.get(True);
            label_models[class_i]       = single_model;
            n_pos_per_label[class_i]    = npos;
            n_neg_per_label[class_i]    = nneg;
            label_inds_left.remove(class_i);
            pass;
        else:
            #print "--- left: %d, in_Q: %d, out_Q: %d" % (len(label_inds_left),in_Q.qsize(),out_Q.qsize());
            time.sleep(1);
            pass; # end else
        
        pass; # end while not...
    

    classifier['label_models']      = label_models;
    classifier['n_pos_per_label']   = n_pos_per_label;
    classifier['n_neg_per_label']   = n_neg_per_label;
    
    return classifier;

def feed_single_label_task_to_process__logit(in_Q,out_Q,X):
    while not in_Q.empty():
 #       print "in_Q still has %d tasks to draw" % in_Q.qsize();
        try:
            (class_i,label_name,y,train_dir)    = in_Q.get(True,1);
            model_file                          = get_single_logit_model_file(train_dir,label_name);
            # Was this model already trained?
            if os.path.exists(model_file):
                fid                             = file(model_file,'rb');
                model_data                      = pickle.load(fid);
                fid.close();
                single_model                    = model_data['single_model'];
                npos                            = model_data['npos'];
                nneg                            = model_data['nneg'];
                print "*** Loading already trained model for %s" % label_name;
                pass;
            else:
                (single_model,npos,nneg)        = train_single_logit_model(\
                    class_i,label_name,X,y);
                if single_model != None:
                    model_data                      = {\
                        'single_model':single_model,\
                        'npos':npos,\
                        'nneg':nneg};
                    fid                             = file(model_file,'wb');
                    pickle.dump(model_data,fid);
                    fid.close();
                    pass; # end if single_model != None
                pass; # end else

#            print ">>> putting into out queue %d:%s" % (class_i,label_name);
            out_Q.put((class_i,label_name,single_model,npos,nneg));
            pass; # end try...
        except:
            print "!!! Caught exception trying to train model for label %d: %s" % (class_i,label_name);
            traceback.print_exc();
            pass; # end except

#        print ">>> done with iteration of %d:%s" % (class_i,label_name);
        pass; # end while not...

    out_Q.close();
    return;

def get_single_logit_model_file(train_dir,label_name):
    return os.path.join(train_dir,"%s.pickle" % label_name);

def train_single_logit_model(class_i,label_name,X,y):
    min_examples        = 2;
    # Do we have enough training material for this label:
    npos            = numpy.sum(y);
    nneg            = numpy.sum(numpy.logical_not(y));
    if (npos >= min_examples and nneg >= min_examples):
        # First do a grid search to select value for parameter C:
        (c_max,score_max)   = grid_search__logit(X,y);
#        print "== internal cross validation selected C=%f (cv score: %f)" % (c_max,score_max);

        # Now train with the selected C and the entire train set:
        single_model        = sklearn.linear_model.LogisticRegression(\
            solver='lbfgs',\
            class_weight='auto',fit_intercept=True,C=c_max);
        single_model.fit(X,y);

        print "+++ Trained model for label %d: %s (%d pos. %d neg. C=%f. CV score=%f)" \
              % (class_i,label_name,npos,nneg,c_max,score_max);
        pass;
    else:
        single_model    = None;
        npos            = 0;
        nneg            = 0;
        pass;

    return (single_model,npos,nneg);


def grid_search__logit(X,y):
    test_portion    = 0.3;
    c_values        = [1e-3,1e-2,1e-1,1e0,1e1,1e2];
    (train_inds,test_inds)  = semirandomly_partition_examples(y,test_portion);
    X_train         = X[train_inds,:];
    y_train         = y[train_inds];
    X_test          = X[test_inds,:];
    y_test          = y[test_inds];
    
    pos_portion     = numpy.mean(y_test);
    pos_weight      = 1. / pos_portion;
    neg_weight      = 1. - pos_weight;
    weight_test     = neg_weight * numpy.ones(len(y_test));
    weight_test[numpy.where(y_test)[0]] = pos_weight;

    score_max       = 0.;
    c_max           = 1.;
    for c_val in c_values:
        model       = sklearn.linear_model.LogisticRegression(\
            solver='lbfgs',\
            class_weight='auto',fit_intercept=True,C=c_val);
        model.fit(X_train,y_train);
        y_hat       = model.predict(X_test);
        (tpr,tnr,accuracy)  = binary_classification_success_rates(y_test,y_hat);
        score       = (tpr + tnr) / 2.;
        if score > score_max:
            score_max   = score;
            c_max       = c_val;
            pass;
        pass;

    return (c_max,score_max);


### Multi-layer logistic regression (multi-logit):    
def classify__multilayer_logit(x,classifier):
    n_layers            = len(classifier['layer_classifiers']);
    layer_input         = x;

    for (layer_i,layer_classifier) in enumerate(classifier['layer_classifiers']):
        (layer_out_bin,layer_out_prob)  = classify__logit(layer_input,layer_classifier);
        if layer_i < (n_layers-1):
            # Prepare the input for the next layer:

            if classifier['model_params']['standardize_features']:
                # Standardize the latest layer's output:
                output_old              = numpy.copy(layer_out_prob);
                layer_out_prob          = standardize_features(layer_out_prob,layer_classifier['output_mean_vec'],layer_classifier['output_std_vec']);
                pass;

            if 'layer_input_policy' not in classifier['model_params']:
                classifier['model_params']['layer_input_policy']    = 'no_augment';
                pass;
      
            if classifier['model_params']['layer_input_policy'] == 'augment_previous_input':
                layer_input             = numpy.concatenate((numpy.reshape(layer_input,(1,-1)),numpy.reshape(layer_out_prob,(1,-1))),axis=1);
                pass;
            elif classifier['model_params']['layer_input_policy'] == 'augment_lower_input':
                layer_input             = numpy.concatenate((numpy.reshape(x,(1,-1)),numpy.reshape(layer_out_prob,(1,-1))),axis=1);
                pass;
            elif classifier['model_params']['layer_input_policy'] == 'no_augment':
                layer_input             = layer_out_prob;
                pass;
            else:
                raise ValueError("Got unsupported value for model parameter 'layer_input_policy': %s" % classifier['model_params']['layer_input_policy']);
            
            pass; # end if there's next layer
        pass; # end for layer_i...

    return (layer_out_bin,layer_out_prob);

def train_classifier__multilayer_logit(X,instances_labels,label_names,classifier):
    n_layers            = classifier['model_params']['n_layers'];
    n_instances         = X.shape[0];
    n_labels            = len(label_names);
    layer_inputs        = X;

    layer_classifiers   = [None for layer_i in range(n_layers)];
    for layer_i in range(n_layers):
        # Train the current layer classifier:
        print "="*20;
        print "==== Training layer %d of the classifier" % layer_i;
        layer_classifier                = {'model_params':pickle.loads(pickle.dumps(classifier['model_params']))};
        # Make subdir for the layer classifier training:
        layer_train_dir                 = os.path.join(classifier['model_params']['train_dir'],'layer_%d' % layer_i);
        if not os.path.exists(layer_train_dir):
            os.mkdir(layer_train_dir);
            pass;
        layer_classifier['model_params']['train_dir']   = layer_train_dir;
        layer_classifier                = train_classifier__logit(layer_inputs,instances_labels,label_names,layer_classifier);
        layer_classifiers[layer_i]      = layer_classifier;
        
        if layer_i < (n_layers-1):
            # Prepare the input for the next layer:

            layer_outputs               = numpy.zeros((n_instances,n_labels));
            for ii in range(n_instances):
                (out_bin,out_prob)      = classify__logit(layer_inputs[ii,:],layer_classifier);
                layer_outputs[ii,:]     = out_prob;
                pass;
            
            if classifier['model_params']['standardize_features']:
                # Standardize (and save the standardization parameters):
                outputs_old             = numpy.copy(layer_outputs);
                (layer_outputs,mv,sv)   = estimate_standardization(layer_outputs);
                layer_classifiers[layer_i]['output_mean_vec']       = mv;
                layer_classifiers[layer_i]['output_std_vec']        = sv;
                pass;

            if 'layer_input_policy' not in classifier['model_params']:
                classifier['model_params']['layer_input_policy']    = 'no_augment';
                pass;
      
            if classifier['model_params']['layer_input_policy'] == 'augment_previous_input':
                layer_inputs            = numpy.concatenate((layer_inputs,layer_outputs),axis=1);
                pass;
            elif classifier['model_params']['layer_input_policy'] == 'augment_lower_input':
                layer_inputs            = numpy.concatenate((X,layer_outputs),axis=1);
                pass;
            elif classifier['model_params']['layer_input_policy'] == 'no_augment':
                layer_inputs            = layer_outputs;
                pass;
            else:
                raise ValueError("Got unsupported value for model parameter 'layer_input_policy': %s" % classifier['model_params']['layer_input_policy']);
            
            pass; # end if there's next layer
        pass; # end for layer_i...

    classifier['layer_classifiers']     = layer_classifiers;
    return classifier;

def main():


    return;

if __name__ == "__main__":
    main();


