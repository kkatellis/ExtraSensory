'''
collect_features.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. November 2014.
'''
import os;
import os.path;
import json;
import numpy;
import warnings;

import compute_features;
import user_statistics;
import audio_representation;

import pdb;


fid                         = file('env_params.json','rb');
g__env_params               = json.load(fid);
fid.close();
g__data_superdir            = g__env_params['data_superdir'];
g__sensors_with_3axes       = ['raw_acc','raw_gyro','raw_magnet',\
                               'proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];
g__raw_sensors              = ['raw_acc','raw_gyro','raw_magnet'];
g__processed_sensors        = ['proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];
g__pseudo_sensors           = ['lf_measurements','location_quick_features','audio_properties','discrete_measurements'];

g__location_quick_features  = ['std_lat','std_long','lat_change','long_change',\
                               'mean_abs_lat_deriv','mean_abs_long_deriv'];
g__lqf_positive_degrees     = ['std_lat','std_long',\
                               'mean_abs_lat_deriv','mean_abs_long_deriv'];
g__low_freq_measurements    = ['light','pressure','proximity_cm','proximity',\
                               'relative_humidity',\
                               'on_the_phone','battery_level','screen_brightness',\
                               'temperature_ambient'];
g__discrete_measurements    = {'wifi_status':[0,1,2],\
                               'app_state':[0,1,2],\
                               'battery_state':[0,1,2,3,'unknown','not_charging','discharging','charging','full'],\
                               'battery_plugged':['ac','usb','wireless'],\
                               'ringer_mode':['normal','silent_no_vibrate','silent_with_vibrate']};
g__audio_properties         = ['max_abs_value','normalization_multiplier'];
g__feats_needing_log_comp   = ['max_abs_value','normalization_multiplier','light'];

g__main_activities          = ['LYING_DOWN','SITTING','STANDING_IN_PLACE','STANDING_AND_MOVING',\
                               'WALKING','RUNNING','BICYCLING'];#,"DON'T_REMEMBER"];

g__secondary_activities     = [];
g__moods                    = [];

g__sr                       = 40.;

def get_all_sensor_names():
    sensors                 = list(g__sensors_with_3axes);
    sensors.append('location');
    sensors.append('audio');
    sensors.append('watch_acc');
    sensors.append('watch_compass');
    sensors.extend(g__pseudo_sensors);
    sensors = sorted(sensors);
    
    return sensors;
    
def get_dim_of_discrete_measurements():
    dim         = 0;
    for key in g__discrete_measurements.keys():
        dim     += len(g__discrete_measurements[key]);
        pass;

    return dim;

def get_discrete_measurements(instance_dir):
    dim         = get_dim_of_discrete_measurements();
    feats       = numpy.zeros(dim);
    input_file  = os.path.join(instance_dir,'m_lf_measurements.json');
    if not os.path.exists(input_file):
        return feats;

    fid         = file(input_file,'rb');
    lf_meas     = json.load(fid);
    fid.close();

    offset      = 0;
    for key in sorted(g__discrete_measurements.keys()):
        values  = g__discrete_measurements[key];
        if key in lf_meas:
            value   = lf_meas[key];
            if value in values:
                ind = offset + values.index(value);
                feats[ind]  = 1;
            pass;
        offset  += len(values);
        pass;

    return feats;
    
def get_pseudo_sensor_features(instance_dir,sensor):
    if sensor == 'discrete_measurements':
        return get_discrete_measurements(instance_dir);
    
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

            if feature_name in g__location_quick_features:
                # Detect and adjust invalid values of location degrees:
                if abs(value) > 0.5:
                    # Deviations of more than half a degree are infeasible
                    value   = numpy.nan;
                    pass;
                
            if feature_name in g__lqf_positive_degrees:
                # These values must be non negative
                if value < 0.:
                    value   = numpy.nan;
                    pass;
                pass;

            features[fi]    = value;
            pass;
        pass;

    return features;

def get_features_from_measurements(instance_dir,timestamp,sensor,audio_encoder):
    if sensor in g__pseudo_sensors:
        return get_pseudo_sensor_features(instance_dir,sensor);

    if sensor == 'audio':
        return audio_representation.get_instance_audio_representation(instance_dir,audio_encoder);


    measurements_file       = os.path.join(instance_dir,'m_%s.dat' % sensor);
    default_features        = numpy.nan*numpy.ones(get_feature_dimension_for_sensor_type(sensor));
    if not os.path.exists(measurements_file):
        return default_features;

    # Load the measurements time-series:
    with warnings.catch_warnings():
        warnings.simplefilter("ignore");
        X                       = numpy.genfromtxt(measurements_file);
        pass;

    

    if (len(X.shape) <= 0):
        return default_features;

    if (X.size <= 0):
        return default_features;
    
    if sensor[:3] == 'raw' or sensor[:4] == 'proc':
        # Then the first column is for time reference:
        timerefs            = X[:,0];
        X                   = X[:,1:];
        pass;

    if sensor == 'watch_compass':
        timerefs            = X[:,0]/1000.;
        X                   = X[:,1];
        pass;
    
    if sensor == 'watch_acc':
        if X.shape[1] == 4:
            timerefs        = X[:,0]/1000.;
            X               = X[:,1:];
            pass;
        else:
            timerefs        = 0.040 * numpy.array(range(X.shape[0])); # (Assuming constant sampling rate of 25Hz)
            pass;

        features            = compute_features.get_watch_acc_features(timerefs,X);
        return features;

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

    if sensor == 'watch_compass':
        features            = compute_features.get_compass_features(timerefs,X);
        return features;

    return default_features;

def check_presence_of_measurements(instance_dir,sensor):
    if sensor in g__pseudo_sensors:
        feat    = get_pseudo_sensor_features(instance_dir,sensor);
        return not numpy.all(numpy.isnan(feat));

    if sensor == 'audio':
        mfcc_file   = os.path.join(instance_dir,'sound.mfcc');
        if not os.path.exists(mfcc_file):
            return False;
        try:
            with warnings.catch_warnings():
                warnings.simplefilter("ignore");
                mfcc    = numpy.genfromtxt(mfcc_file,delimiter=',');
                pass;
            
            return mfcc.size > 39;
            pass;
        except:
            return False;

    measurements_file       = os.path.join(instance_dir,'m_%s.dat' % sensor);
    if not os.path.exists(measurements_file):
        return False;

    # Load the measurements time-series:
    with warnings.catch_warnings():
        warnings.simplefilter("ignore");
        X                       = numpy.genfromtxt(measurements_file);
        pass;

    if (len(X.shape) <= 0):
        return False;
    
    return True;


def get_uuid_data_dir(uuid):
    return os.path.join(g__data_superdir,uuid);

def get_instance_features(uuid,timestamp_str,sensors,feat2sensor_map,audio_encoder):
    uuid_dir                = os.path.join(g__data_superdir,uuid);
    instance_dir            = os.path.join(uuid_dir,timestamp_str);

    if not os.path.exists(instance_dir):
        return None;

    timestamp               = float(timestamp_str);
    features                = {'timestamp':timestamp};

    feature_vec             = numpy.nan*numpy.ones((1,len(feat2sensor_map)));
    for (si,sensor) in enumerate(sensors):
#        print "%s:%s" % (timestamp_str,sensor);
        vec                 = get_features_from_measurements(\
            instance_dir,timestamp,sensor,audio_encoder);
        feature_vec[0,feat2sensor_map==si]  = vec;
        pass; # end for sensor...

    return feature_vec;

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

def get_feature_dimension_for_sensor_type(sensor,audio_rep_dim=0):
    if sensor in g__sensors_with_3axes:
        dim     = compute_features.dimension_of_3d_series_features();
    elif sensor == 'location':
        dim     = compute_features.dimension_of_location_features();
    elif sensor == 'lf_measurements':
        dim     = len(g__low_freq_measurements);
    elif sensor == 'discrete_measurements':
        dim     = get_dim_of_discrete_measurements();
    elif sensor == 'location_quick_features':
        dim     = len(g__location_quick_features);
    elif sensor == 'audio_properties':
        dim     = len(g__audio_properties);
    elif sensor == 'audio':
        dim     = audio_rep_dim;
    elif sensor == 'watch_acc':
        dim     = compute_features.dimension_of_3d_series_features();
    elif sensor == 'watch_compass':
        dim     = compute_features.dimension_of_watch_compass_features();
    else:
        dim     = 0;
        pass;

    return dim;

def get_feature_dimension_for_aggregate_of_sensors(sensors,audio_rep_dim=0):
    ind_vecs    = [];
    for (si,sensor) in enumerate(sensors):
        dim         = get_feature_dimension_for_sensor_type(sensor,audio_rep_dim);
        ind_vecs.append(si*numpy.ones(dim,dtype=int));
        pass;

    feat2sensor_map = numpy.concatenate(tuple(ind_vecs));
    total_dim       = feat2sensor_map.size;

    return (total_dim,feat2sensor_map);
    
def initialize_feature_matrices(num_instances,sensors):
    features                = {};
    for sensor in sensors:
        dim     = get_feature_dimension_for_sensor_type(sensor);
        if dim <= 0:
            continue;
        
        features[sensor]    = numpy.nan * numpy.ones((num_instances,dim));
        pass;

    return features;


def collect_features_and_labels(uuids,model_params,audio_encoder):
    sensors                 = model_params['sensors'];
    feat2sensor_map         = model_params['feat2sensor_map'];
    
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
        uuid_dir        = get_uuid_data_dir(uuid);
        if not os.path.exists(uuid_dir):
            print '--- Missing uuid: %s' % uuid;
            continue;
        
        print '### uuid: %s' % uuid;
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
            feature_vec  = get_instance_features(\
                uuid,subdir,sensors,feat2sensor_map,audio_encoder);

            # Append this instance to train set:
            instances_features.append(feature_vec);
            instances_labels    = numpy.concatenate((instances_labels,bin_vec),axis=0);
            pass; # end for subdir...
        
        pass; # end for uuid...

    # Turn the feature vector collection to a large matrix:
    X       = numpy.concatenate(tuple(instances_features),axis=0);
    return (X,instances_labels,label_names);

def user_sensor_counts(uuids):
    sensors         = get_all_sensor_names();
    n_uuids         = len(uuids);
    n_sensors       = len(sensors);
    counts          = numpy.zeros((n_uuids,n_sensors),dtype=int);
    for (ui,uuid) in enumerate(uuids):
        uuid_dir        = get_uuid_data_dir(uuid);
        if not os.path.exists(uuid_dir):
            print '--- Missing uuid: %s' % uuid;
            continue;
        
        print '### uuid: %s' % uuid;
        for subdir in os.listdir(uuid_dir):
            instance_dir    = os.path.join(uuid_dir,subdir);
            if not os.path.isdir(instance_dir):
                continue;

            for (si,sensor) in enumerate(sensors):
#                print "%s:%s" % (instance_dir,sensor);
                if check_presence_of_measurements(instance_dir,sensor):
                    counts[ui,si]   += 1;
                    pass;
                pass; # end for sensor...

            pass; # end for subdir...
        
        pass; # end for (ui,uuid)...

    return (counts,sensors);


##def features_per_user(uuid,sensors):
##    uuid_dir = os.path.join(g__data_superdir,uuid);
##    user_instances          = os.listdir(uuid_dir);
##    n_instances             = len(user_instances);
##    
##    uuid_feats              = initialize_feature_matrices(\
##        n_instances,sensors);
##    main_vec                = -numpy.ones(n_instances);
##    main_mat                = numpy.zeros((n_instances,len(g__main_activities)),dtype=bool);
##    secondary_mat           = numpy.zeros((n_instances,len(g__secondary_activities)),dtype=bool);
##    mood_mat                = numpy.zeros((n_instances,len(g__moods)),dtype=bool);
##    
##    for (ii,timestamp_str) in enumerate(user_instances):
##        if not ii%20:
##            print "%d) %s" % (ii,timestamp_str);
##            pass;
##        instance_dir = os.path.join(uuid_dir,timestamp_str);
##        if not os.path.isdir(instance_dir):
##            continue;
##
##        instance_feats      = get_instance_features(uuid,timestamp_str,sensors);
##        for sensor in sensors:
##            feat_vec        = instance_feats[sensor];
##            if feat_vec == None or len(feat_vec) <= 0:
##                continue;
##
##            uuid_feats[sensor][ii]  = feat_vec;
##            pass; # end for sensor...
##
##        # Read the labels:
##        (main_activity,\
##         secondary_activities,\
##         moods) = user_statistics.get_instance_labels(instance_dir);
##        main_ind            = main_activity_string2int(main_activity);
##        main_vec[ii]        = main_ind;
##        if main_ind >= 0:
##            main_mat[ii,main_ind]   = True;
##            pass;
##
##        if secondary_activities != None:
##            secondary_mat[ii]   = secondary_activities_strings2binary(secondary_activities);
##            pass;
##        if moods != None:
##            mood_mat[ii]        = moods_strings2binary(moods);
##            pass;
##        pass; # end for (ii,timestamp)...
##
##    print "done with %d instances for user" % len(user_instances);
##    return (uuid_feats,main_vec,main_mat,secondary_mat,mood_mat);

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
    return user_statistics.standardize_label(label);

def main():

    uuids                   = [];
    fid                     = file('real_uuids.list','rb');
    for line in fid:
        line                = line.strip();
        if line.startswith('#'):
            continue;

        uuids.append(line);
        pass;
    fid.close();


    (counts,sensors)        = user_sensor_counts(uuids);
    pdb.set_trace();

    read_secondary_labels();
    read_mood_labels();
    
    sensors                 = list(g__sensors_with_3axes);
    sensors.append('location');
    sensors.extend(g__pseudo_sensors);

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


