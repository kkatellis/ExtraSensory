'''
classification_test.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. November 2014.
'''
import os;
import os.path;
import sys;
import numpy;
import pickle;
import json;

import collect_features;
import classifiers;
import user_statistics;

import pdb;


def train_phase(train_uuids,model_params):
    print "="*20;
    # Collect the train set:
    print "== Collecting train examples...";
    (instances_features,\
     instances_labels,\
     label_names)   = collect_features.collect_features_and_labels(train_uuids);
    
    print "Train set: %d instances" % len(instances_features);
    
    # Train the classifier:
    print "== Training classifier of type: %s..." % model_params;
    classifier  = classifiers.train_classifier(\
        instances_features,instances_labels,\
        label_names,model_params);

    return classifier;

def test_phase(test_uuids,classifier):
    print "="*20;
    # Collect the test set:
    print "== Collecting test examples...";
    (instances_features,\
     instances_labels_gt,\
     label_names)   = collect_features.collect_features_and_labels(test_uuids);
    (n_samples,n_classes)   = instances_labels_gt.shape;
    print "Test set: %d instances. %d classes." % (n_samples,n_classes);

    print "== Testing classifier on the test set...";
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
    scores      = get_classification_scores(instances_labels_gt,instances_labels_machine,instances_label_probs,label_names);
    return scores;

def get_classification_scores(instances_labels_gt,instances_labels_machine,instances_label_probs,label_names):
    scores      = {'n_samples':instances_labels_gt.shape[0],\
                   'label_names':label_names};
    
    (tpr_per_label,tnr_per_label,accuracy_per_label)    = classifiers.binary_classification_success_rates(\
        instances_labels_gt,instances_labels_machine);
    scores['tpr_per_label']         = tpr_per_label;
    scores['tnr_per_label']         = tnr_per_label;
    scores['accuracy_per_label']    = accuracy_per_label;

    (soft_tpr,soft_tnr,soft_accuracy)   = classifiers.soft_classification_success_rates(\
        instances_labels_gt,instances_label_probs);
    scores['soft_tpr_per_label']    = soft_tpr;
    scores['soft_tnr_per_label']    = soft_tnr;
    scores['soft_accuracy_per_label']   = soft_accuracy;
    return scores;



def leave_one_out_cross_validation(uuids,model_params):

    scores_per_fold = [];
    for (ui,test_uuid) in enumerate(uuids):
        print "#"*30;
        print "### CV fold %d: test uuid is %s" % (ui,test_uuid);
        test_uuids  = [test_uuid];
        train_uuids = set(uuids).difference(test_uuids);

        classifier  = train_phase(train_uuids,model_params);
        fold_scores = test_phase(test_uuids,classifier);
        fold_scores['classifier']   = classifier;
        scores_per_fold.append(fold_scores);
        pass;

    return scores_per_fold;

def main():

    if len(sys.argv) > 1:
        inparam_file    = sys.argv[1];
        fid             = file(inparam_file,'rb');
        inparams        = json.load(fid);
        fid.close();
        model_params    = inparams;

        if inparams['sensor_set'] == 'all_sensors':
            sensors     = collect_features.get_all_sensor_names();
            pass;
        else:
            sensors     = None;######### NEed to handle this case
            pass;
        model_params.pop('sensor_set');
        dim             = collect_features.get_feature_dimension_for_aggregate_of_sensors(sensors);

        model_params['sensors']             = sensors;
        model_params['feature_dimension']   = dim;

        output_file     = inparams['output_file'];
        model_params.pop('output_file');
        pass;
    else:
        all_sensors     = collect_features.get_all_sensor_names();
        dim             = collect_features.get_feature_dimension_for_aggregate_of_sensors(all_sensors);
        model_params    = {'model_type':'logit',\
                           'sensors':all_sensors,\
                           'feature_dimension':dim,\
                           'missing_value_policy':'zero_imputation',\
                           'standardize_features':True};
        output_file     = 'cv_results.pickle';
        pass;

    uuids   = user_statistics.read_subjects_uuids();

    scores_per_fold     = leave_one_out_cross_validation(uuids,model_params);
    fid = file(output_file,'wb');
    pickle.dump(scores_per_fold,fid);
    fid.close();
    pdb.set_trace();
    return;

if __name__ == "__main__":
    main();


