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


fid                         = file('params.json','rb');
g__params                   = json.load(fid);
fid.close();
g__data_superdir            = g__params['data_superdir'];
g__sensors_with_3axes       = ['raw_acc','raw_gyro','raw_magnet',\
                               'proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];
g__raw_sensors              = ['raw_acc','raw_gyro','raw_magnet'];
g__processed_sensors        = ['proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];
g__pseudo_sensors           = ['lf_measurements','location_quick_features','audio_properties'];

g__location_quick_features  = ['std_lat','std_long','lat_change','long_change',\
                               'mean_abs_lat_deriv','mean_abs_long_deriv'];
g__low_freq_measurements    = ['light','pressure','proximity_cm','proximity',\
                               'relative_humidity','wifi_status','app_state',\
                               'on_the_phone','battery_level','screen_brightness'];
g__audio_properties         = ['max_abs_value','normalization_multiplier'];
g__feats_needing_log_comp   = ['max_abs_value','light'];

g__main_activities          = ['LYING_DOWN','SITTING','STANDING_IN_PLACE','STANDING_AND_MOVING',\
                               'WALKING','RUNNING','BICYCLING',"DON'T_REMEMBER"];

g__secondary_activities     = [];
g__moods                    = [];

g__sr                       = 40.;

def get_all_sensor_names():
    sensors                 = list(g__sensors_with_3axes);
    sensors.append('location');
    sensors.extend(g__pseudo_sensors);

    return sensors;
    

def get_pseudo_sensor_features(instance_dir,sensor):
    if sensor == 'lf_measurements':
        expected_features = g__low_freq_measurements;
        pass;
    elif sensor == 'location_quick_features':
        expected_features = g__location_quick_features;
        pass;
    elif sensor == 'audio_properties':
        expected_features = g__audio_properties;
        pass;
    else:
        return None;

    dim         = get_feature_dimension_for_sensor_type(sensor);
    features    = numpy.nan*numpy.ones(dim);

    input_file  = os.path.join(instance_dir,'m_%s.json' % sensor);
    if not os.path.exists(input_file):
        return features;

    fid         = file(input_file,'rb');
    input_data  = json.load(fid);
    fid.close();

    for (fi,feature_name) in enumerate(expected_features):
        if feature_name in input_data:
            value           = input_data[feature_name];
            if feature_name in g__feats_needing_log_comp:
                epsilon     = 0.00001;
                value       = compute_features.log_compression(value,epsilon);
                pass;
            features[fi]    = value;
            pass;
        pass;

    return features;
    
def get_features_from_measurements(instance_dir,timestamp,sensor):
    if sensor in g__pseudo_sensors:
        return get_pseudo_sensor_features(instance_dir,sensor);
    
    measurements_file       = os.path.join(instance_dir,'m_%s.dat' % sensor);
    default_features        = numpy.nan*numpy.ones(get_feature_dimension_for_sensor_type(sensor));
    if not os.path.exists(measurements_file):
        return default_features;

    # Load the measurements time-series:
    X                       = numpy.genfromtxt(measurements_file);

    if (len(X.shape) <= 0):
        return default_features;
    
    if sensor[:3] == 'raw' or sensor[:4] == 'proc':
        # Then the first column is for time reference:
        timerefs            = X[:,0];
        X                   = X[:,1:];
        pass;

    if sensor in g__sensors_with_3axes:
        # Estimate the average sampling rate:
        dur                 = timerefs[-1] - timerefs[0];
        sr                  = float(X.shape[0]) / dur;
        features            = compute_features.get_3d_series_features(X,sr);
        return features;

    if sensor == 'location':
        if (len(X.shape) == 1):
            X = numpy.reshape(X,(1,-1));
            pass;
        features            = compute_features.get_location_features(X,timestamp);
        return features;

    return default_features;

def get_uuid_data_dir(uuid):
    return os.path.join(g__data_superdir,uuid);

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

def get_instance_labels_in_binary(instance_dir,main_labels,secondary_labels):
    (main_activity,\
     secondary_activities,\
     moods) = user_statistics.get_instance_labels(instance_dir);
    if (main_activity == None or type(secondary_activities) != list):
        return (None,None);

    main_labels_bin         = get_binary_labels([main_activity],main_labels);
    secondary_labels_bin    = get_binary_labels(secondary_activities,secondary_labels);

    return (main_labels_bin,secondary_labels_bin);

def get_binary_labels(applied_labels,label_names):
    n_classes       = len(label_names);
    bin_vec         = numpy.zeros(n_classes,dtype=bool);
    for (li,label) in enumerate(label_names):
        bin_vec[li] = (label in applied_labels);
        pass;

    return bin_vec;

def get_feature_dimension_for_sensor_type(sensor):
    if sensor in g__sensors_with_3axes:
        dim     = compute_features.dimension_of_3d_series_features();
    elif sensor == 'location':
        dim     = compute_features.dimension_of_location_features();
    elif sensor == 'lf_measurements':
        dim     = len(g__low_freq_measurements);
    elif sensor == 'location_quick_features':
        dim     = len(g__location_quick_features);
    elif sensor == 'audio_properties':
        dim     = len(g__audio_properties);
    else:
        dim     = 0;
        pass;

    return dim;

def get_feature_dimension_for_aggregate_of_sensors(sensors):
    total_dim   = 0;
    for sensor in sensors:
        total_dim   += get_feature_dimension_for_sensor_type(sensor);
        pass;

    return total_dim;
    
def initialize_feature_matrices(num_instances,sensors):
    features                = {};
    for sensor in sensors:
        dim     = get_feature_dimension_for_sensor_type(sensor);
        if dim <= 0:
            continue;
        
        features[sensor]    = numpy.nan * numpy.ones((num_instances,dim));
        pass;

    return features;


def collect_features_and_labels(uuids):
    sensors                 = get_all_sensor_names();
    main_label_names        = get_main_labels();
    sec_label_names         = get_secondary_labels();
    label_names             = main_label_names[:];
    label_names.extend(sec_label_names);
    n_classes               = len(label_names);

    # Prepare the structures for instances' features and labels:
    instances_features  = [];
    instances_labels    = numpy.zeros((0,n_classes),dtype=bool);

    # Go over the instances to collect the training data:
    for uuid in uuids:
        print '### uuid: %s' % uuid;
        uuid_dir        = get_uuid_data_dir(uuid);
        for subdir in os.listdir(uuid_dir):
            instance_dir    = os.path.join(uuid_dir,subdir);
            if not os.path.isdir(instance_dir):
                continue;

            # Get labels:
            (main_labels_bin,sec_labels_bin)    = get_instance_labels_in_binary(\
                instance_dir,main_label_names,sec_label_names);
            if (type(main_labels_bin) == type(None) or type(sec_labels_bin) == type(None)):
                continue;
            bin_vec         = numpy.concatenate((main_labels_bin,sec_labels_bin));
            bin_vec         = numpy.reshape(bin_vec,(1,-1));

            # Get features:
            instance_feats  = get_instance_features(\
                uuid,subdir,sensors);

            # Append this instance to train set:
            instances_features.append(instance_feats);
            instances_labels    = numpy.concatenate((instances_labels,bin_vec),axis=0);
            pass; # end for subdir...
        
        pass; # end for uuid...

    return (instances_features,instances_labels,label_names);

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

    print "done with %d instances for user" % len(user_instances);
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

def get_main_labels():
    return g__main_activities;

def get_secondary_labels():
    if (len(g__secondary_activities) <= 0):
        read_secondary_labels();
        pass;

    return g__secondary_activities;

def get_mood_labels():
    if (len(g__moods) <= 0):
        read_mood_labels();
        pass;

    return g__moods;

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
    sensors.extend(g__pseudo_sensors);

    uuids                   = [];
    fid                     = file('real_uuids.list','rb');
    for line in fid:
        line                = line.strip();
        if line.startswith('#'):
            continue;

        uuids.append(line);
        pass;
    fid.close();

    feats_per_uuid = {};
    for uuid in uuids:
        print "="*20;
        print "=== uuid: %s" % uuid;
        
        (uuid_feats,main_vec,main_mat,secondary_mat,mood_mat) = features_per_user(uuid,sensors);
        feats_per_uuid[uuid] = uuid_feats;
        pass;

    pdb.set_trace();

    return;

if __name__ == "__main__":
    main();


