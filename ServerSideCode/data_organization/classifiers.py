'''
classifiers.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. June 2015.
'''

import numpy;
import sklearn.linear_model;

import pdb;

def classify(instance_features,classifier):
    if classifier['model_params']['model_type'] == 'logit':
        (bin_vec,prob_vec)  = classify_logit(instance_features,classifier);
        pass;
    else:
        (bin_vec,prob_vec)  = (None,None);
        pass;
    
    return (bin_vec,prob_vec);

def train_classifier(instances_features,instances_labels,label_names,model_params):
    if 'model_type' not in model_params:
        classifier  = None;
        pass;
    elif model_params['model_type'] == 'logit':
        classifier  = train_classifier_logit(instances_features,instances_labels,label_names,model_params);
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
### Specific classifiers:
#########################

def get_valid_examples(feats):
    n_examples          = feats.shape[0];
    invalid             = numpy.where(numpy.isnan(feats));
    invalid_inds        = set(invalid[0]);

    valid_inds          = list(set(range(n_examples)).difference(invalid_inds));
    valid_examples      = feats[valid_inds,:];

    return (valid_inds,valid_examples);

def apply_missing_values_policy(feature_vector,policy):
    is_missing          = numpy.logical_or(numpy.isnan(feature_vector),numpy.isinf(feature_vector));
    if policy == 'zero_imputation':
        feature_vector[is_missing]  = 0;
        pass;
    elif policy == 'missing_indicators':
        feature_vector[is_missing]  = 0;
        feature_vector              = numpy.concatenate((feature_vector,is_missing.astype(feature_vector.dtype)));
        pass;
    else:
        # Leave the feature vector as it is
        pass;

    return feature_vector;

### Logistic regression (logit):
def construct_feature_vector_logit(instance_features,model_params):
    # Construct a single feature vector for this instance:
    x           = numpy.zeros(0);
    for sensor in model_params['sensors']:
        x       = numpy.concatenate((x,instance_features[sensor]));
        pass;
    x           = numpy.reshape(x,(1,-1));

    x           = apply_missing_values_policy(x,model_params['missing_value_policy']);

##    acc_vec     = instance_features['raw_acc'];
##    gyr_vec     = instance_features['proc_gyro'];
##    mag_vec     = instance_features['proc_magnet'];
##    locq_vec    = instance_features['location_quick_features'];
##
##    x           = numpy.concatenate((acc_vec,gyr_vec,mag_vec,locq_vec));
##    x           = numpy.reshape(x,(1,-1));
    
    return x;
    
def classify_logit(instance_features,classifier):
    x           = construct_feature_vector_logit(instance_features,classifier['model_params']);
    
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

def train_classifier_logit(instances_features,instances_labels,label_names,model_params):
    n_samples   = len(instances_features);
    (n_samples2,n_classes)  = instances_labels.shape;
    if (n_samples2 != n_samples):
        raise Exception('Cant train classifier. Got %d instances but %d labels' % (n_samples,n_sampmles2));
    
    # Construct the training sampels features:
    dim         = model_params['feature_dimension'];
    X           = numpy.zeros((n_samples,dim));
    for ii in range(n_samples):
        
        X[ii,:] = construct_feature_vector_logit(instances_features[ii],model_params);
        pass;
    # Get rid of invalid examples:
    (valid_inds,X)      = get_valid_examples(X);
    instances_labels    = instances_labels[valid_inds,:];
    n_samples           = X.shape[0];
    
    # Go over the labels classes and for each construct a binary classifier:
    label_models        = [];
    n_pos_per_label     = [];
    n_neg_per_label     = [];
    min_examples        = 2;
    for ci in range(n_classes):
        y       = instances_labels[:,ci];
        # Do we have enough training material for this label:
        npos            = numpy.sum(y);
        nneg            = numpy.sum(numpy.logical_not(y));
        if (npos >= min_examples and nneg >= min_examples):
            # First do a grid search to select value for parameter C:
            (c_max,score_max)   = grid_search_logit(X,y);
            print "== internal cross validation selected C=%f (cv score: %f)" % (c_max,score_max);

            # Now train with the selected C and the entire train set:
            single_model        = sklearn.linear_model.LogisticRegression(\
                class_weight='auto',fit_intercept=True,C=c_max);
            single_model.fit(X,y);
    
            print "+++ Trained model for label %d: %s (%d pos. %d neg)" \
                  % (ci,label_names[ci],npos,nneg);
            pass;
        else:
            single_model    = None;
            npos            = 0;
            nneg            = 0;
            pass;
        
        label_models.append(single_model);
        n_pos_per_label.append(npos);
        n_neg_per_label.append(nneg);
        pass;

    classifier  = {'model_params':model_params,\
                   'label_names':label_names,\
                   'label_models':label_models,\
                   'n_pos_per_label':n_pos_per_label,\
                   'n_neg_per_label':n_neg_per_label};
    
    return classifier;

def grid_search_logit(X,y):
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



def main():


    return;

if __name__ == "__main__":
    main();


