'''
classifiers.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. June 2015.
'''

import numpy;
import sklearn.linear_model;
import traceback;
import multiprocessing;
import time;

import pdb;

def classify(instance_features,classifier):
    # Prepare a feature vector (assuming this isn't an ensemble classifier):
    x           = construct_feature_vector(instance_features,classifier['model_params']);
    if classifier['model_params']['standardize_features']:
        # Standardize the vector:
        x       = standardize_features(x,classifier['mean_vec'],classifier['std_vec']);
        pass;
    
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

def train_classifier(instances_features,instances_labels,label_names,model_params):
    if 'model_type' not in model_params:
        return None;

    n_samples   = len(instances_features);
    n_samples2  = instances_labels.shape[0];
    if (n_samples2 != n_samples):
        raise Exception('Cant train classifier. Got %d instances but %d labels' % (n_samples,n_sampmles2));
    
    # Construct the training sampels features:
    dim         = get_feature_dim(model_params);
    X           = numpy.zeros((n_samples,dim));
    for ii in range(n_samples):     
        X[ii,:] = construct_feature_vector(instances_features[ii],model_params);
        pass;

    classifier  = {'model_params':model_params,'label_names':label_names};
    if model_params['standardize_features']:
        # Standardize (and save the standardization parameters):
        (X,mean_vec,std_vec)    = estimate_standardization(X);
        classifier['mean_vec']  = mean_vec;
        classifier['std_vec']   = std_vec;
        pass;

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
Apply some policy to handle missing values in a feature vector.

Input:
feature_vector: din-array of features. Values of NaN, inf or -inf are regarded as missing values.
policy: string. One of:
    'zero_imputation': replace every missing value with value of zero.
    'missing_indicators': replace every missing value with value of zero,
    and augment to the feature vector an indicator vector of the same dimension din,
    where each indicator has 1 if the corresponding feature is missing and 0 otherwise.

Output:
feature_vector: dout-array of features.
    The feature vector, after being handled with the selected policy,
    possibly now having a different dimension than the input feature vector.
'''
def apply_missing_values_policy(feature_vector,policy):
    is_missing          = numpy.logical_or(numpy.isnan(feature_vector),numpy.isinf(feature_vector));
    if policy == 'zero_imputation':
        feature_vector[is_missing]  = 0;
        pass;
    elif policy == 'missing_indicators':
        feature_vector[is_missing]  = 0;
        feature_vector              = numpy.concatenate((feature_vector,is_missing.astype(feature_vector.dtype)));
        feature_vector              = numpy.reshape(feature_vector,(1,-1));
        pass;
    else:
        # Leave the feature vector as it is
        pass;

    return feature_vector;

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
    mean_vec        = numpy.mean(X,axis=0);
    std_vec         = numpy.std(X,axis=0);
    Z               = standardize_features(X,mean_vec,std_vec);

    return (Z,mean_vec,std_vec);

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
    # Go over the labels classes and for each construct a binary classifier:
    in_Q                = multiprocessing.Queue();
    out_Q               = multiprocessing.Queue();
    label_models        = [None for ci in range(n_classes)];
    n_pos_per_label     = numpy.zeros(n_classes);
    n_neg_per_label     = numpy.zeros(n_classes);
    # Fill the process queue with tasks:
    for ci in range(n_classes):
        y       = instances_labels[:,ci].astype(int);
        in_Q.put((ci,label_names[ci],y));
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
    while not out_Q.empty() or not in_Q.empty():
        if not out_Q.empty():
            # Get the results of a task:
            (class_i,label_name,single_model,npos,nneg) = out_Q.get(True);
            label_models[class_i]       = single_model;
            n_pos_per_label[class_i]    = npos;
            n_neg_per_label[class_i]    = nneg;
            pass;
        else:
            time.sleep(1);
            pass;
        pass;

        classifier['label_models']      = label_models;
        classifier['n_pos_per_label']   = n_pos_per_label;
        classifier['n_neg_per_label']   = n_neg_per_label;
    
    return classifier;

def feed_single_label_task_to_process__logit(in_Q,out_Q,X):
    while not in_Q.empty():
#        print "in_Q still has %d tasks to draw" % in_Q.qsize();
        try:
            (class_i,label_name,y)  = in_Q.get(True,1);
            (single_model,npos,nneg) = train_single_logit_model(\
                class_i,label_name,X,y);
            out_Q.put((class_i,label_name,single_model,npos,nneg));
            pass;
        except:
            print "!!! Caught exception trying to train model for label %d: %s" % (class_i,label_name);
            traceback.print_exc();
        pass;

    out_Q.close();
    return;

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
            if 'layer_input_policy' not in classifier['model_params']:
                classifier['model_params']['layer_input_policy']    = 'no_augment';
                pass;
      
            if classifier['model_params']['layer_input_policy'] == 'augment_previous_input':
                layer_input             = numpy.concatenate((layer_input,layer_out_prob));
                pass;
            elif classifier['model_params']['layer_input_policy'] == 'augment_lower_input':
                layer_input             = numpy.concatenate((x,layer_out_prob));
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
        layer_classifier                = {'model_params':classifier['model_params']};
        layer_classifier                = train_classifier__logit(layer_inputs,instances_labels,label_names,layer_classifier);
        layer_classifiers[layer_i]      = layer_classifier;
        
        if layer_i < (n_layers-1):
            # Prepare the input for the next layer:
            layer_outputs               = numpy.zeros((n_instances,n_labels));
            for ii in range(n_instances):
                (out_bin,out_prob)      = classify__logit(layer_inputs[ii,:],layer_classifier);
                layer_outputs[ii,:]     = out_prob;
                pass;
            
            if 'layer_input_policy' not in classifier['model_params']:
                classifier['model_params']['layer_input_policy']    = 'no_augment';
                pass;
      
            if classifier['model_params']['layer_input_policy'] == 'augment_previous_input':
                layer_inputs            = numpy.concatenate((layer_inputs,layer_outputs));
                pass;
            elif classifier['model_params']['layer_input_policy'] == 'augment_lower_input':
                layer_inputs            = numpy.concatenate((X,layer_outputs));
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


