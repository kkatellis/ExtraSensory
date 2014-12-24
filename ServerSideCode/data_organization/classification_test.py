'''
classification_test.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. November 2014.
'''
import os;
import os.path;
import json;
import numpy;
import sklearn.svm;
import sklearn.linear_model;

import collect_features;
import annotation_retrieval;

import pdb;


g__sensors_with_3axes       = ['raw_acc','raw_gyro','raw_magnet',\
                               'proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];


def feat_dim_per_sensor(sensor):
    if sensor == 'location':
        return 11;

    if sensor in g__sensors_with_3axes:
        return 41;
        
    return 0;

def collect_sublist_features(sublist_uuids,feats_per_uuid,main_per_uuid,secondary_per_uuid,mood_per_uuid):
    if len(sublist_uuids) <= 0:
        return (None,None);

    # Initialize the labels:
    labels              = {};
    d_main              = main_per_uuid[sublist_uuids[0]].shape[1];
    labels['main']      = numpy.zeros((0,d_main),dtype=bool);
    d_sec               = secondary_per_uuid[sublist_uuids[0]].shape[1];
    labels['secondary'] = numpy.zeros((0,d_sec),dtype=bool);
    d_mood              = mood_per_uuid[sublist_uuids[0]].shape[1];
    labels['mood']      = numpy.zeros((0,d_mood),dtype=bool);

    # Initialize the features:
    feats               = {};
    sensors             = sorted(feats_per_uuid[sublist_uuids[0]].keys());
    for sensor in sensors:
        feats[sensor]   = numpy.nan*numpy.ones((0,feat_dim_per_sensor(sensor)));
        pass; # end for sensor...

    uuid_index          = numpy.zeros(0,dtype=int);
    
    # Go over the uuids and add the labels and features:
    for (u_index,uuid) in enumerate(sublist_uuids):
        added_main      = main_per_uuid[uuid];
        labels['main']  = numpy.concatenate((labels['main'],added_main),axis=0);
        added_sec       = secondary_per_uuid[uuid];
        labels['secondary'] = numpy.concatenate((labels['secondary'],added_sec),axis=0);
        added_mood      = mood_per_uuid[uuid];
        labels['mood']  = numpy.concatenate((labels['mood'],added_mood),axis=0);

        for sensor in sensors:
            uuid_feats      = feats_per_uuid[uuid][sensor];
            feats[sensor]   = numpy.concatenate((feats[sensor],uuid_feats),axis=0);
            pass; # end for sensor...

        added_indices   = u_index * numpy.ones(len(added_main),dtype=int);
        uuid_index      = numpy.concatenate((uuid_index,added_indices),axis=0);
        pass; # end for uuid...
    
    return (labels,feats,uuid_index);

def cross_validation(feats_per_uuid,main_per_uuid,secondary_per_uuid,mood_per_uuid):
    uuids                   = sorted(feats_per_uuid.keys());

    for ui in range(len(uuids)):
        print "#"*30;
        print "#### CV fold %d. Test uuid: %s" % (ui,uuids[ui]);
        
        # Train set:
        train_uuids         = set(uuids);
        train_uuids.remove(uuids[ui]);
        train_uuids         = list(train_uuids);
        (train_labels,train_feats,train_uinds)  = collect_sublist_features(\
            train_uuids,feats_per_uuid,main_per_uuid,\
            secondary_per_uuid,mood_per_uuid);

        # Test set:
        test_uuids          = [uuids[ui]];
        (test_labels,test_feats,test_uinds)  = collect_sublist_features(\
            test_uuids,feats_per_uuid,main_per_uuid,\
            secondary_per_uuid,mood_per_uuid);

        print "### Train models...";
        model_per_sensor    = train_models(train_labels,train_feats,train_uinds);
        print "### Classification probabilities...";
        (class_prob,prob_tensors,sensor_vals)   = classify(model_per_sensor,test_feats);
        print "### Calc scores...";
        scores              = get_classification_scores(class_prob,prob_tensors,sensor_vals,test_labels,test_uinds);
        pdb.set_trace();
        pass; # end for ui...

    return;

def get_valid_examples(feats):
    n_examples          = feats.shape[0];
    invalid             = numpy.where(numpy.isnan(feats));
    invalid_inds        = set(invalid[0]);

    valid_inds          = list(set(range(n_examples)).difference(invalid_inds));
    valid_examples      = feats[valid_inds,:];

    return (valid_inds,valid_examples);

##############
## Classifiers


def train_models(train_labels,train_feats,train_uinds):
    model_per_sensor    = {};
    for sensor in train_feats.keys():
        sensor_feats    = train_feats[sensor];
        (valid_inds,sensor_feats)   = get_valid_examples(sensor_feats);

        model_per_label_type    = {};
        for label_type in train_labels.keys():
            label_mat   = train_labels[label_type];
            label_mat   = label_mat[valid_inds,:];
            
            # Now go over every label and train a simple model for it:
            model_per_label     = [];
            for li in range(label_mat.shape[1]):
                label_vec       = label_mat[:,li];
                has_negatives   = not numpy.prod(label_vec,dtype=bool);
                has_positives   = numpy.sum(label_vec) > 0;
                if (has_negatives and has_positives):
                    model       = train_single_model(label_vec,sensor_feats);
                    print "%s. %s: %d." % (sensor,label_type,li);
                    pass;
                else:
                    model       = None;
                    pass;
                model_per_label.append(model);
                pass; # end for li...

            model_per_label_type[label_type]    = model_per_label;
            pass; # end for label_type...
        
        model_per_sensor[sensor]    = model_per_label_type;
        pass; # end for sensor...
    
    return model_per_sensor;

def train_single_model(y,X):
    single_model    = sklearn.linear_model.LogisticRegression(\
        class_weight='auto',fit_intercept=True);
    single_model.fit(X,y);
    
    return single_model;

def predict_with_single_model(X,single_model):
    prob_mat        = single_model.predict_proba(X);
    pos_ind         = single_model.label_.tolist().index(1);
    prob_vec        = prob_mat[:,pos_ind];
    
    return prob_vec;

def classify(model_per_sensor,test_feats):

    sensor_vals = test_feats.keys();
    n_sensors   = len(sensor_vals);
    n_examples  = test_feats[sensor_vals[0]].shape[0];
    label_types = model_per_sensor[sensor_vals[0]].keys();
    
    class_prob  = {};
    prob_tensors= {};
    for label_type in label_types:
        n_labels        = len(model_per_sensor[sensor_vals[0]][label_type]);
        prob_tensor     = numpy.nan*numpy.ones((n_examples,n_labels,n_sensors));

        for (si,sensor) in enumerate(sensor_vals):
            X                   = test_feats[sensor];
            (valid_inds,X)       = get_valid_examples(X);

            model_per_label     = model_per_sensor[sensor][label_type];
            
            for li in range(len(model_per_label)):
                single_model    = model_per_label[li];
                if (single_model == None):
                    continue;

                print "predic: %s. %s. %d" % (label_type,sensor,li);
                prob_vec        = predict_with_single_model(X,model_per_label[li]);
                prob_tensor[valid_inds,li,si]   = prob_vec;
                pass; # for li ...
            
            pass; # end for sensor...

        prob_tensors[label_type]= prob_tensor;
        # Now we can take the average probability over the ensemble of sensors:
        avr_prob        = numpy.nanmean(prob_tensor,axis=2);
        class_prob[label_type]  = avr_prob;
        pass; # end for label_type...

    return (class_prob,prob_tensors,sensor_vals);

def get_classification_scores(class_prob,prob_tensors,sensor_vals,test_labels,test_uinds):
    scores       = {};

    for label_type in class_prob.keys():
        scores[label_type]  = {};
        scores[label_type]['avr_sensor']    = get_classification_scores_single_mat(\
            class_prob[label_type],test_labels[label_type],test_uinds);
        for (si,sensor) in enumerate(sensor_vals):
            scores[label_type][sensor]      = get_classification_scores_single_mat(\
                prob_tensors[label_type][:,:si],test_labels[label_type],test_uinds);
            pass;
        pass;

    return scores;
    
def get_classification_scores_single_mat(class_prob,test_labels,test_uinds):
    scores      = {};
    ann     = annotation_retrieval.\
              get_performance_measures(\
                  class_prob[label_type],test_labels[label_type],\
                  desired_measures=['annotation']);
    ret     = annotation_retrieval.\
              get_performance_measures(\
                  class_prob[label_type].T,test_labels[label_type].T,\
                  desired_measures=['auc','p10','mean_ap']);
    for measure in ['precision','recall','f']:
        scores[measure]     = ann[measure];
        per_tag                         = "%s_per_tag" % measure;
        scores[per_tag]     = ann[per_tag];
        pass;
    for measure in ['auc','p10','mean_ap']:
        scores[measure]     = ret[measure];
        pass;

    scores['correlation']   = numpy.nanmean(class_prob*test_labels-class_prob*numpy.logical_not(test_labels),axis=0);

    return scores;

def main():

    sensors                 = list(g__sensors_with_3axes);
    sensors.append('location');
    
    uuids                   = [];
    fid                     = file('real_uuids.list','rb');
    for line in fid:
        line                = line.strip();
        if line.startswith('#'):
            continue;

        uuids.append(line);
        pass;
    fid.close();

    secondary_labels        = collect_features.read_secondary_labels();
    mood_labels             = collect_features.read_mood_labels();


    print "#"*30;
    print "#### Reading all features...";
    feats_per_uuid          = {};
    main_per_uuid           = {};
    secondary_per_uuid      = {};
    mood_per_uuid           = {};
    for uuid in uuids:
        print "="*20;
        print "== uuid: %s" % uuid;
        (uuid_feats,main_vec,main_mat,\
         secondary_mat,mood_mat)    = collect_features.features_per_user(\
             uuid,sensors);

        feats_per_uuid[uuid]        = uuid_feats;
        main_per_uuid[uuid]         = main_mat;
        secondary_per_uuid[uuid]    = secondary_mat;
        mood_per_uuid[uuid]         = mood_mat;
        pass;

    cross_validation(feats_per_uuid,main_per_uuid,secondary_per_uuid,mood_per_uuid);
    pdb.set_trace();

    return;

if __name__ == "__main__":
    main();


