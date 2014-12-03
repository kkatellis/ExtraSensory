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

import pdb;


g__data_superdir            = 'uuids';
g__sensors_with_3axes       = ['raw_acc','raw_gyro','raw_magnet',\
                               'proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];
g__raw_sensors              = ['raw_acc','raw_gyro','raw_magnet'];
g__processed_sensors        = ['proc_acc','proc_gravity','proc_gyro',\
                               'proc_attitude','proc_magnet'];

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
            features[sensor]    = numpy.nan * numpy.ones((41,num_instances));
            continue;
        if sensor == 'location':
            features[sensor]    = numpy.nan * numpy.ones((11,num_instances));
            continue;
        
        pass;

    return features;

def features_per_user(uuid,sensors):
    uuid_dir = os.path.join(g__data_superdir,uuid);
    user_instances          = os.listdir(uuid_dir);

    uuid_feats              = initialize_feature_matrices(\
        len(user_instances),sensors);
    
    for (ii,timestamp_str) in enumerate(user_instances):
        print "%d) %s" % (ii,timestamp_str);
        instance_dir = os.path.join(uuid_dir,timestamp_str);
        if not os.path.isdir(instance_dir):
            continue;

        instance_feats      = get_instance_features(uuid,timestamp_str,sensors);
        for sensor in sensors:
            feat_vec        = instance_feats[sensor];
            if len(feat_vec) and feat_vec == None:
                continue;
            
            uuid_feats[sensor][:,ii]    = feat_vec;
            pass; # end for sensor...
        
        pass; # end for (ii,timestamp)...


    pdb.set_trace();
    return uuid_feats;



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

    for uuid in uuids:
        print "="*20;
        print "=== uuid: %s" % uuid;
        uuid_feats          = features_per_user(uuid,sensors);

        pdb.set_trace();
        pass;

    return;

if __name__ == "__main__":
    main();


