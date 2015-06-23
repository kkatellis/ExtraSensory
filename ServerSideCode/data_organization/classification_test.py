'''
classification_test.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. November 2014.
'''
import os;
import os.path;
import numpy;

import collect_features;
import classifiers;
import user_statistics;

import pdb;


def train_phase(train_uuids,model_type):
    # Collect the train set:
    (instances_features,\
     instances_labels,\
     label_names)   = collect_features.collect_features_and_labels(train_uuids);
    
    print "="*20;
    print "Train set: %d instances" % len(instances_features);
    
    # Train the classifier:
    classifier  = classifiers.train_classifier(\
        instances_features,instances_labels,\
        label_names,model_type);

    return classifier;

def test_phase(test_uuids,classifier):
    # Collect the test set:
    (instances_features,\
     instances_labels_gt,\
     label_names)   = collect_features.collect_features_and_labels(test_uuids);
    (n_samples,n_classes)   = instances_labels_gt.shape;
    print "="*20;
    print "Test set: %d instances. %d classes." % (n_samples,n_classes);
    
    # Prepare machine labels structs:
    instances_labels_machine    = numpy.zeros((n_samples,n_classes),dtype=bool);
    instances_label_probs       = numpy.zeros((n_samples,n_classes));

    # Go over the instances and machine-classify them:
    for ii in range(n_samples):
        (bin_vec,prob_vec)              = classifiers.classify(\
            instances_features[ii],classifier);
        instances_labels_machine[ii,:]  = bin_vec;
        instances_label_probs[ii,:]     = prob_vec;
        pass;

    # Evaluate classification performance:
    pdb.set_trace();
    return;








    
def get_classification_scores_single_mat(class_prob,test_labels,test_uinds):
    scores      = {};
##    ann     = annotation_retrieval.\
##              get_performance_measures(\
##                  class_prob,test_labels,\
##                  desired_measures=['annotation']);
##    ret     = annotation_retrieval.\
##              get_performance_measures(\
##                  class_prob.T,test_labels.T,\
##                  desired_measures=['auc','p10','mean_ap']);
##    for measure in ['precision','recall','f']:
##        scores[measure]     = ann[measure];
##        per_tag             = "%s_per_tag" % measure;
##        scores[per_tag]     = ann[per_tag];
##        pass;
##    for measure in ['auc','p10','mean_ap']:
##        scores[measure]     = ret[measure];
##        pass;
    scores['correlation']   = numpy.nanmean(class_prob*test_labels-class_prob*numpy.logical_not(test_labels),axis=0);

    return scores;

def leave_one_out_cross_validation(uuids):

    model_type  = 'logit';
    for test_uuid in uuids:
        print "#"*30;
        print "### CV: test uuid is %s" % test_uuid;
        test_uuids  = [test_uuid];
        train_uuids = set(uuids).difference(test_uuids);

        classifier  = train_phase(train_uuids,model_type);
        test_phase(test_uuids,classifier);
        pass;

def main():
    
    uuids   = user_statistics.read_subjects_uuids();

    leave_one_out_cross_validation(uuids);
    
    return;

if __name__ == "__main__":
    main();


