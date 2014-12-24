'''
collect_features.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. November 2014.
'''
import os;
import os.path;
import json;
import numpy;

import compute_features;
import user_statistics;

import pdb;


g__data_superdir            = 'data/raw_data';
g__sensors_with_3axes       = ['raw_acc','raw_gyro','raw_magnet',\
                               'proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];
g__raw_sensors              = ['raw_acc','raw_gyro','raw_magnet'];
g__processed_sensors        = ['proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];

g__main_activities          = ['LYING_DOWN','SITTING','STANDING',\
                               'WALKING','RUNNING','BICYCLING',"DON'T_KNOW"];

g__secondary_activities     = [];
g__moods                    = [];

g__sr                       = 40.;

def get_features_from_measurements(instance_dir,timestamp,sensor):
    measurements_file       = os.path.join(instance_dir,'m_%s' % sensor);
    if not os.path.exists(measurements_file):
        return None;

    # Load the measurements time-series:
    X                       = numpy.genfromtxt(measurements_file);

    if sensor[:3] == 'raw':
        # Then the first column is for time reference:
        timerefs            = X[:,0];
        X                   = X[:,1:];
        pass;

    if sensor in g__sensors_with_3axes:
        features            = compute_features.get_3d_series_features(X,g__sr);
        return features;

    if sensor == 'location':
        features            = compute_features.get_location_features(X,timestamp);
        return features;
        
    return None;

def get_instance_features(uuid,timestamp_str,sensors):
    uuid_dir                = os.path.join(g__data_superdir,uuid);
    instance_dir            = os.path.join(uuid_dir,timestamp_str);

    if not os.path.exists(instance_dir):
        return None;

    timestamp               = float(timestamp_str);
    features                = {'timestamp':timestamp};

    for sensor in sensors:
        features[sensor]    = get_features_from_measurements(\
            instance_dir,timestamp,sensor);
        pass; # end for sensor...

    return features;

def initialize_feature_matrices(num_instances,sensors):
    features                = {};
    for sensor in sensors:
        if sensor in g__sensors_with_3axes:
            features[sensor]    = numpy.nan * numpy.ones((num_instances,41));
            continue;
        if sensor == 'location':
            features[sensor]    = numpy.nan * numpy.ones((num_instances,11));
            continue;
        
        pass;

    return features;

def features_per_user(uuid,sensors):
    uuid_dir = os.path.join(g__data_superdir,uuid);
    user_instances          = os.listdir(uuid_dir);
    n_instances             = len(user_instances);
    
    uuid_feats              = initialize_feature_matrices(\
        n_instances,sensors);
    main_vec                = -numpy.ones(n_instances);
    main_mat                = numpy.zeros((n_instances,len(g__main_activities)),dtype=bool);
    secondary_mat           = numpy.zeros((n_instances,len(g__secondary_activities)),dtype=bool);
    mood_mat                = numpy.zeros((n_instances,len(g__moods)),dtype=bool);
    
    for (ii,timestamp_str) in enumerate(user_instances):
        if not ii%20:
            print "%d) %s" % (ii,timestamp_str);
            pass;
        instance_dir = os.path.join(uuid_dir,timestamp_str);
        if not os.path.isdir(instance_dir):
            continue;

        instance_feats      = get_instance_features(uuid,timestamp_str,sensors);
        for sensor in sensors:
            feat_vec        = instance_feats[sensor];
            if feat_vec == None or len(feat_vec) <= 0:
                continue;
            
            uuid_feats[sensor][ii]  = feat_vec;
            pass; # end for sensor...

        # Read the labels:
        (main_activity,\
         secondary_activities,\
         moods) = user_statistics.get_instance_labels(instance_dir);
        main_ind            = main_activity_string2int(main_activity);
        main_vec[ii]        = main_ind;
        if main_ind >= 0:
            main_mat[ii,main_ind]   = True;
            pass;

        if secondary_activities != None:
            secondary_mat[ii]   = secondary_activities_strings2binary(secondary_activities);
            pass;
        if moods != None:
            mood_mat[ii]        = moods_strings2binary(moods);
            pass;

        pass; # end for (ii,timestamp)...


    return (uuid_feats,main_vec,main_mat,secondary_mat,mood_mat);

def main_activity_string2int(main_activity):
    if main_activity not in g__main_activities:
        return -1;

    return g__main_activities.index(main_activity);

def secondary_activities_strings2binary(secondary_activities):
    bin_vec                 = numpy.zeros(len(g__secondary_activities),dtype=bool);
    for act in secondary_activities:
        if act not in g__secondary_activities:
            print "!!! Got activity not on the list: ", act;
            continue;
        
        act_ind             = g__secondary_activities.index(act);
        bin_vec[act_ind]    = True;
        pass;

    return bin_vec;

def moods_strings2binary(moods):
    bin_vec                 = numpy.zeros(len(g__moods),dtype=bool);
    for mood in moods:
        if mood not in g__moods:
            print "!!! Got mood not on the list: ", mood;
            continue;
        
        mood_ind            = g__moods.index(mood);
        bin_vec[mood_ind]   = True;
        pass;

    return bin_vec;

def read_secondary_labels():
    global g__secondary_activities;
    g__secondary_activities = [];
    fid     = file('label_files/secondaryActivitiesList.txt','rb');
    for line in fid:
        line    = standardize_label(line.strip());
        g__secondary_activities.append(line);
        pass;
    fid.close();
    return g__secondary_activities;

def read_mood_labels():
    global g__moods;
    g__moods                = [];
    fid     = file('label_files/moodsList.txt','rb');
    for line in fid:
        line    = standardize_label(line.strip());
        g__moods.append(line);
        pass;
    fid.close();
    return g__moods;

def standardize_label(label):
    label   = label.upper();
    label   = label.replace(' ','_');

    return label;

def main():

    read_secondary_labels();
    read_mood_labels();
    
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

    for uuid in uuids:
        print "="*20;
        print "=== uuid: %s" % uuid;
        (uuid_feats,main_vec,secondary_mat,mood_mat) = features_per_user(uuid,sensors);

        pdb.set_trace();
        pass;

    return;

if __name__ == "__main__":
    main();


