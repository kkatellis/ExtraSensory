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
import audio_representation;

import pdb;

fid                 = file('env_params.json','rb');
g__env_params       = json.load(fid);
fid.close();
g__exp_supdir       = g__env_params['experiment_superdir'];

def train_phase(train_uuids,model_params):
    print "="*20;

    train_dir           = model_params['train_dir'];
    classifier_file     = os.path.join(train_dir,'classifier.pickle');
    if os.path.exists(classifier_file):
        fid             = file(classifier_file,'rb');
        classifier      = pickle.load(fid);
        fid.close();
        print "<<< Loaded ready classifier file: %s" % classifier_file;
        pass; # end if exists classifier_file...
    else:
        # Prepare audio encoder:
        if 'audio' not in model_params['sensors']:
            audio_encoder   = None;
            pass;
        else:
            audio_params    = model_params['audio_params'];
            audio_enc_file  = os.path.join(train_dir,'audio_encoder.pickle');
            if os.path.exists(audio_enc_file):
                fid             = file(audio_enc_file,'rb');
                audio_encoder   = pickle.load(fid);
                fid.close();
                print "<< Loaded ready audio encoder file: %s" % audio_enc_file;
                pass; # end if exists audio_enc_file...
            else:
                audio_encoder   = audio_representation.train_audio_encoder(sorted(train_uuids),audio_params);
                fid             = file(audio_enc_file,'wb');
                pickle.dump(audio_encoder,fid);
                fid.close();
                print ">> Saved audio encoder file: %s" % audio_enc_file;
                pass; # end else (not exists audio_enc_file)
            pass; # end else (if 'audio' is in sensors)

        # Collect the train set:
        train_set_file  = os.path.join(train_dir,'train_set.pickle');
        if os.path.exists(train_set_file):
            fid         = file(train_set_file,'rb');
            train_set   = pickle.load(fid);
            fid.close();
            X                   = train_set['X'];
            instances_labels    = train_set['instances_labels'];
            label_names         = train_set['label_names'];
            print "<< Loaded train examples from saved file %s" % train_set_file;
            pass; # end if exists train_set_file
        else:
            print "== Collecting train examples...";
            (X,\
             instances_labels,\
             label_names)   = collect_features.collect_features_and_labels(train_uuids,model_params,audio_encoder);
            train_set       = {\
                'X':X,\
                'instances_labels':instances_labels,\
                'label_names':label_names,\
                'model_params':model_params};
            fid             = file(train_set_file,'wb');
            pickle.dump(train_set,fid);
            fid.close();
            print ">> Saved train set file: %s" % train_set_file;
            pass; # end else (not exists train_set_file)

        print "Train set: %d instances" % X.shape[0];
        # Train the classifier:
        print "== Training classifier of type: %s" % model_params['model_type'];
        print "."*10;
        classifier  = classifiers.train_classifier(\
            X,instances_labels,\
            label_names,model_params);
        # Add the audio encoder to the classifier:
        classifier['audio_encoder'] = pickle.loads(pickle.dumps(audio_encoder));
        fid             = file(classifier_file,'wb');
        pickle.dump(classifier,fid);
        fid.close();
        print "+++ Saved classifier file: %s" % classifier_file;
        pass; # end else (not exists classifier_file)

    return classifier;

def test_phase(test_uuids,classifier):
    print "="*20;
    # Collect the test set:
    train_dir       = classifier['model_params']['train_dir'];
    test_set_file   = os.path.join(train_dir,'test_set.pickle');
    if os.path.exists(test_set_file):
        fid         = file(test_set_file,'rb');
        test_set    = pickle.load(fid);
        fid.close();
        X                   = test_set['X'];
        instances_labels_gt = test_set['instances_labels'];
        label_names         = test_set['label_names'];
        print "<< Loaded test examples from saved file %s" % test_set_file;
        pass; # end if esitst test_set_file
    else:
        print "== Collecting test examples...";
        (X,\
         instances_labels_gt,\
         label_names)   = collect_features.collect_features_and_labels(test_uuids,classifier['model_params'],classifier['audio_encoder']);
        test_set        = {\
            'X':X,\
            'instances_labels':instances_labels_gt,\
            'label_names':label_names,\
            'model_params':classifier['model_params']};
        fid             = file(test_set_file,'wb');
        pickle.dump(test_set,fid);
        fid.close();
        print ">> Saved test set file: %s" % test_set_file;
        pass; # end else (if not exists test_set_file)

    (n_samples,n_classes)   = instances_labels_gt.shape;
    print "Test set: %d instances. %d classes." % (n_samples,n_classes);

    print "== Testing classifier on the test set...";
    # Prepare machine labels structs:
    instances_labels_machine    = numpy.zeros((n_samples,n_classes),dtype=bool);
    instances_label_probs       = numpy.zeros((n_samples,n_classes));

    # Go over the instances and machine-classify them:
    for ii in range(n_samples):
        (bin_vec,prob_vec)              = classifiers.classify(\
            X[ii,:],classifier);
        instances_labels_machine[ii,:]  = bin_vec;
        instances_label_probs[ii,:]     = prob_vec;
        pass;

    # Evaluate classification performance:
    scores      = classifiers.get_classification_scores(instances_labels_gt,instances_labels_machine,instances_label_probs,label_names);
    return scores;


def construct_cross_validation_folds(uuids,n_folds):
    cv_folds        = [];
    sorted_uuids    = sorted(uuids);
    n_uuids         = len(uuids);
    uuids_per_fold  = int(n_uuids / n_folds);
    for foldi in range(n_folds):
        start       = foldi*uuids_per_fold;
        if foldi == n_folds-1:
            stop    = n_uuids;
            pass;
        else:
            stop    = (foldi+1)*uuids_per_fold;
            pass;

        test_uuids  = sorted_uuids[start:stop];
        train_uuids = sorted(set(sorted_uuids).difference(set(test_uuids)));
        cv_folds.append({'test_uuids':test_uuids,'train_uuids':train_uuids});

        pass;

    return cv_folds;

def leave_one_out_cross_validation(uuids,model_params):
    cv_folds        = construct_cross_validation_folds(uuids,len(uuids));
    return cross_validation(cv_folds,model_params);

def summarize_folds_scores(scores_per_fold):
    n_labels        = len(scores_per_fold[0]['label_names']);
    scores          = summarize_folds_scores_helper(scores_per_fold,n_labels);
    # Add summary of random chance scores:
    random_per_fold = [];
    for fold_scores in scores_per_fold:
        random_per_fold.append(fold_scores['random_chance']);
        pass;
    scores['random_chance'] = summarize_folds_scores_helper(random_per_fold,n_labels);
    return scores;

def summarize_folds_scores_helper(scores_per_fold,n_labels):
    n_folds         = len(scores_per_fold);
    mp5_vals        = numpy.nan*numpy.ones(n_folds);
    mr5_vals        = numpy.nan*numpy.ones(n_folds);
    mf5_vals        = numpy.nan*numpy.ones(n_folds);
    map_vals        = numpy.nan*numpy.ones(n_folds);
    naive_tprs      = numpy.nan*numpy.ones((n_folds,n_labels));
    naive_tnrs      = numpy.nan*numpy.ones((n_folds,n_labels));
    top5_tprs       = numpy.nan*numpy.ones((n_folds,n_labels));
    top5_tnrs       = numpy.nan*numpy.ones((n_folds,n_labels));

    for (foldi,fold_scores) in enumerate(scores_per_fold):
        mp5_vals[foldi]     = fold_scores['mp5'];
        mr5_vals[foldi]     = fold_scores['mr5'];
        mf5_vals[foldi]     = fold_scores['mf5'];
        map_vals[foldi]     = fold_scores['map'];
        naive_tprs[foldi,:] = fold_scores['naive_tprs'];
        naive_tnrs[foldi,:] = fold_scores['naive_tnrs'];
        top5_tprs[foldi,:]  = fold_scores['top5_tprs'];
        top5_tnrs[foldi,:]  = fold_scores['top5_tnrs'];
        pass;

    folds_scores                = {};
    folds_scores['mp5_vals']    = mp5_vals;
    folds_scores['mr5_vals']    = mr5_vals;
    folds_scores['mf5_vals']    = mf5_vals;
    folds_scores['map_vals']    = map_vals;
    folds_scores['naive_tprs']  = naive_tprs;
    folds_scores['naive_tnrs']  = naive_tnrs;
    naive_trs                   = (naive_tprs+naive_tnrs)/2.;
    folds_scores['naive_trs']   = naive_trs;
    folds_scores['top5_tprs']   = top5_tprs;
    folds_scores['top5_tnrs']   = top5_tnrs;
    top5_trs                    = (top5_tprs+top5_tnrs)/2.;
    folds_scores['top5_trs']    = top5_trs;

    avr_scores                  = {};
    avr_scores['mp5']           = numpy.mean(mp5_vals);
    avr_scores['mr5']           = numpy.mean(mr5_vals);
    avr_scores['mf5']           = numpy.mean(mf5_vals);
    avr_scores['map']           = numpy.mean(map_vals);
    avr_scores['naive_tprs']    = numpy.mean(naive_tprs,axis=0);
    avr_scores['naive_tnrs']    = numpy.mean(naive_tnrs,axis=0);
    avr_scores['naive_trs']     = numpy.mean(naive_trs,axis=0);
    avr_scores['top5_tprs']     = numpy.mean(top5_tprs,axis=0);
    avr_scores['top5_tnrs']     = numpy.mean(top5_tnrs,axis=0);
    avr_scores['top5_trs']      = numpy.mean(top5_trs,axis=0);

    scores                      = {\
        'scores_per_fold':scores_per_fold,\
        'folds_scores':folds_scores,\
        'avr_scores':avr_scores};
    return scores;

def cross_validation(cv_folds,model_params):
    scores_per_fold = [];
    for (foldi,fold) in enumerate(cv_folds):
        test_uuids  = fold['test_uuids'];
        train_uuids = fold['train_uuids'];
        print "#"*30;
        print "### CV fold %d. Test uuids are:" % foldi;
        for uuid in test_uuids:
            print "### %s" % uuid;
            pass;
        
        # Create dir for this fold:
        fold_dir    = os.path.join(model_params['experiment_dir'],"fold_%d" % foldi);
        if not os.path.exists(fold_dir):
            os.mkdir(fold_dir);
            pass;
        model_params['train_dir']   = fold_dir;
        
        classifier  = train_phase(train_uuids,model_params);
        fold_scores = test_phase(test_uuids,classifier);
        fold_scores['classifier']   = classifier;
        scores_per_fold.append(fold_scores);

        pass;

    scores              = summarize_folds_scores(scores_per_fold);
    scores['cv_folds']  = cv_folds;
    
    return scores;

def main():

    if len(sys.argv) > 1:
        inparam_file    = sys.argv[1];
        fid             = file(inparam_file,'rb');
        inparams        = json.load(fid);
        fid.close();
        model_params    = inparams;

        # Experiment dir:
        expname         = model_params['experiment_name'];
        expdir          = os.path.join(g__exp_supdir,expname);
        if not os.path.exists(expdir):
            os.mkdir(expdir);
            pass;
        model_params['experiment_dir']  = expdir;
        output_file     = os.path.join(expdir,"res__%s.pickle" % expname);

        if inparams['sensor_set'] == 'all_sensors':
            sensors     = collect_features.get_all_sensor_names();
            pass;
        elif inparams['sensor_set'] == 'all_sensors_except_audio':
            sensors     = collect_features.get_all_sensor_names();
            sensors.remove('audio_properties');
            sensors.remove('audio');
        else:
            sensors     = None;######### NEed to handle this case
            pass;
        model_params.pop('sensor_set');

        enc_params      = {'tau':4};
        audio_params    = {'k':20,'minibatch_size':300,'init_batch_size':500,'n_minibatches':40,'encoder_params':enc_params};
        model_params['audio_params']    = audio_params;
        (total_dim,feat2sensor_map)     = collect_features.get_feature_dimension_for_aggregate_of_sensors(sensors,audio_params['k']);

        model_params['sensors']             = sensors;
        model_params['feature_dimension']   = total_dim;
        model_params['feat2sensor_map']     = feat2sensor_map;

        pass;
    else:
        raise Error("missing experiment parameters file");
        pass;

    uuids               = user_statistics.read_subjects_uuids();
    cv_folds            = construct_cross_validation_folds(uuids,2);

    scores              = cross_validation(cv_folds,model_params);
    fid = file(output_file,'wb');
    pickle.dump(scores,fid);
    fid.close();
    pdb.set_trace();
    return;

if __name__ == "__main__":
    main();


