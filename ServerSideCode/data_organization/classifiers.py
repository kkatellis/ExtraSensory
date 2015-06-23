'''
classifiers.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. June 2015.
'''

import numpy;
import sklearn.linear_model;

import pdb;

def classify(instance_features,classifier):
    if classifier['model_type'] == 'logit':
        (bin_vec,prob_vec)  = classify_logit(instance_features,classifier);
        pass;
    else:
        (bin_vec,prob_vec)  = (None,None);
        pass;
    
    return (bin_vec,prob_vec);

def train_classifier(instances_features,instances_labels,label_names,model_type):
    if model_type == 'logit':
        classifier  = train_classifier_logit(instances_features,instances_labels,label_names);
        pass;
    else:
        classifier  = None;
        pass;
    
    return classifier;


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

### Logistic regression (logit):
def construct_feature_vector_logit(instance_features):
    # Construct a single feature vector for this instance:
    acc_vec     = instance_features['raw_acc'];
    gyr_vec     = instance_features['proc_gyro'];
    mag_vec     = instance_features['raw_magnet'];
    locq_vec    = instance_features['location_quick_features'];

    x           = numpy.concatenate((acc_vec,gyr_vec,mag_vec,locq_vec));
    x           = numpy.reshape(x,(1,-1));
    
    return x;
    
def classify_logit(instance_features,classifier):
    x           = construct_feature_vector_logit(instance_features);
    
    # Use the pre-trained models to predict:
    n_classes   = len(classifier['label_models']);
    prob_vec    = numpy.zeros(n_classes);
    if (numpy.sum(numpy.isnan(x)) <= 0):
        for ci in range(n_classes):
            single_model    = classifier['label_models'][ci];
            if (single_model != None):
                pos_ind         = single_model.label_.tolist().index(1);
                prob_vec[ci]    = single_model.predict_proba(x)[0,pos_ind];
                pass;
            pass;
        pass;
    
    bin_vec     = prob_vec > 0.5;
    
    return (bin_vec,prob_vec);

def train_classifier_logit(instances_features,instances_labels,label_names):
    n_samples   = len(instances_features);
    (n_samples2,n_classes)  = instances_labels.shape;
    if (n_samples2 != n_samples):
        raise Exception('Cant train classifier. Got %d instances but %d labels' % (n_samples,n_sampmles2));
    
    # Construct the training sampels features:
    dim         = 108;
    X           = numpy.zeros((n_samples,dim));
    for ii in range(n_samples):
        X[ii,:] = construct_feature_vector_logit(instances_features[ii]);
        pass;
    # Get rid of invalid examples:
    (valid_inds,X)      = get_valid_examples(X);
    instances_labels    = instances_labels[valid_inds,:];
    n_samples           = X.shape[0];
    
    # Go over the labels classes and for each construct a binary classifier:
    label_models        = [];
    n_pos_per_label     = [];
    n_neg_per_label     = [];
    for ci in range(n_classes):
        y       = instances_labels[:,ci];
        # Do we have enough training material for this label:
        has_positives   = numpy.sum(y) > 0;
        has_negatives   = not numpy.prod(y,dtype=bool);
        if (has_positives and has_negatives):
            single_model    = sklearn.linear_model.LogisticRegression(\
                class_weight='auto',fit_intercept=True);
            single_model.fit(X,y);
            npos        = numpy.sum(y);
            nneg        = numpy.sum(numpy.logical_not(y));
    
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

    classifier  = {'model_type':'logit',\
                   'label_names':label_names,\
                   'label_models':label_models,\
                   'n_pos_per_label':n_pos_per_label,\
                   'n_neg_per_label':n_neg_per_label};
    
    return classifier;

def main():


    return;

if __name__ == "__main__":
    main();


