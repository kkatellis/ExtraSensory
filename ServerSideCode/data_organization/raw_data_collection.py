'''
raw_data_collection.py

This module is to organize the collected data from ExtraSensory app.
The collected measurements are sent in a zip file (sometimes including also labels from active-feedback) and the labels can also be provided through the api.

This module can help collect them together to an organized directory per user.
This is to be used offline, unrelated to the web service.
--------------------------------------------------------------------------
Written by Yonatan Vaizman. October 2014.
'''
import os;
import fnmatch;
import subprocess;
import json;
import zipfile;
import numpy as np;
import mlpy;
import shutil;


g__data_zip_dir = '/Library/WebServer/Documents/rmw/feedback';
g__feedback_superdir = '/Library/WebServer/Documents/rmw/classifier/feats';
g__output_superdir = '/Users/yonatan/Documents/collected_data';

g__lf_fields = [\
    'altitude','floor','horizontal_accuracy','vertical_accuracy',\
    'wifi_status','app_state','device_orientation','proximity',\
    'on_the_phone'];

def collect_all_instances_of_uuid(uuid,skip_existing):
    for filename in os.listdir(g__data_zip_dir):
        if fnmatch.fnmatch(filename,'*-%s.zip' % uuid):
            print filename;
            parts = filename.split('-');
            timestamp = parts[0];
            collect_single_instance(uuid,timestamp,skip_existing);

            pass; # end if fnmatch...
        pass; # end for filename...

    return;

def collect_single_instance(uuid,timestamp,skip_existing):
    # First check if there is any source of data for this uuid and timestamp:
    input_zip_filename = '%s-%s.zip' % (timestamp,uuid);
    input_zip_file = os.path.join(g__data_zip_dir,input_zip_filename);
    if not os.path.exists(input_zip_file):
        print "-- no zip file %s" % input_zip_file;
        return False;

    # Prepare the output dir:
    uuid_out_dir = os.path.join(g__output_superdir,uuid);
    if not os.path.exists(uuid_out_dir):
        os.mkdir(uuid_out_dir);
        pass;

    instance_out_dir = os.path.join(uuid_out_dir,timestamp);
    if os.path.exists(instance_out_dir):
        if skip_existing:
            print "vvv skipping";
            return True;
        pass;
    else:
        os.mkdir(instance_out_dir);
        pass;

    # Extract the contents of the zip file:
    zf = zipfile.ZipFile(input_zip_file);
    zf.extractall(instance_out_dir);

    # Verify there is the high frequency data file:
    hf_file = os.path.join(instance_out_dir,"HF_DUR_DATA.txt");
    if not os.path.exists(hf_file):
        print "-- no HF data file";
        # Delete the newly created dir:
        os.rmdir(instance_out_dir);
        print "--- Removed dir: %s" % instance_out_dir;
        return False;

    # If there is a label-feedback file, copy it:
    feedback_file = os.path.join(os.path.join(os.path.join(g__feedback_superdir,uuid),timestamp),'feedback');
    if os.path.exists(feedback_file):
        shutil.copy(feedback_file,instance_out_dir);
        print "++ Copied feedback file";
        pass;
    else:
        # Check if there are labels from active feedback:
        active_label_file = os.path.join(instance_out_dir,'label.txt');
        if os.path.exists(active_label_file):
            analyze_active_labels_file(active_label_file,instance_out_dir,uuid,timestamp);
            pass; # end if exists active_label_file
        else:
            print "-- No feedback file and no active label.txt file";
            pass; # end else (if exists active_label_file)

        pass; # end else (if exists feedback_file)

    # Read the measurements file and save the different modalities to files:
    new_version = True;
    if new_version:
        (raw_acc,raw_magnet,raw_gyro,proc_timeref,proc_acc,proc_magnet,proc_gyro,proc_gravity,proc_attitude,location,lf_data) = read_datafile(hf_file);

        np.savetxt(os.path.join(instance_out_dir,'raw_acc'),raw_acc);
        np.savetxt(os.path.join(instance_out_dir,'raw_magnet'),raw_magnet);
        np.savetxt(os.path.join(instance_out_dir,'raw_gyro'),raw_gyro);

        np.savetxt(os.path.join(instance_out_dir,'proc_timeref'),proc_timeref);

        np.savetxt(os.path.join(instance_out_dir,'proc_acc'),proc_acc);
        np.savetxt(os.path.join(instance_out_dir,'proc_magnet'),proc_magnet);
        np.savetxt(os.path.join(instance_out_dir,'proc_gyro'),proc_gyro);
        np.savetxt(os.path.join(instance_out_dir,'proc_gravity'),proc_gravity);
        np.savetxt(os.path.join(instance_out_dir,'proc_attitude'),proc_attitude);

        np.savetxt(os.path.join(instance_out_dir,'location'),location);
        pass;
    else:
        (acc,magnet,gyro,location,lf_data) = read_datafile_json_list(hf_file);
        pass;

    # Save measurement data to modality-separate files:
        np.savetxt(os.path.join(instance_out_dir,'acc'),acc);
        np.savetxt(os.path.join(instance_out_dir,'magnet'),magnet);
        np.savetxt(os.path.join(instance_out_dir,'gyro'),gyro);
        np.savetxt(os.path.join(instance_out_dir,'location'),location);
        pass;

    lf_out_file = os.path.join(instance_out_dir,'lf_measurements.dat');
    fid = open(lf_out_file,'wb');
    json.dump(lf_data,fid);
    fid.close();
    if len(lf_data) > 0:
        print "++ Created low-frequency measures file";
        pass;

    return True;

def analyze_active_labels_file(active_label_file,instance_out_dir,uuid,timestamp):
    fid = file(active_label_file,'rb');
    in_jlist = lson.load(fid);
    fid.close();

    out_jlist = {'active_feedback':'true','uuid':uuid,'timestamp':timestamp};

    out_jlist['corrected_activity'] = in_jlist['mainActivity'];
    out_jlist['secondary_activities'] = in_jlist['secondaryActivities'];
    out_jlist['mood'] = in_jlist['mood'];

    print "++ Active feedback labels copied to feedback file";

    return;

def read_datafile(hf_file):
    # open the file for reading
    fid = open(hf_file, "r");
    jdict = json.load(fid);
    fid.close();

    raw_acc = np.array([jdict['raw_acc_timeref'],jdict['raw_acc_x'],jdict['raw_acc_y'],jdict['raw_acc_z']]).T;
    raw_gyro = np.array([jdict['raw_gyro_timeref'],jdict['raw_gyro_x'],jdict['raw_gyro_y'],jdict['raw_gyro_z']]).T;
    raw_magnet = np.array([jdict['raw_magnet_timeref'],jdict['raw_magnet_x'],jdict['raw_magnet_y'],jdict['raw_magnet_z']]).T;

    proc_acc = np.array([jdict['processed_user_acc_x'],jdict['processed_user_acc_y'],jdict['processed_user_acc_z']]).T;
    proc_magnet = np.array([jdict['processed_magnet_x'],jdict['processed_magnet_y'],jdict['processed_magnet_z']]).T;
    proc_gyro = np.array([jdict['processed_gyro_x'],jdict['processed_gyro_y'],jdict['processed_gyro_z']]).T;

    proc_gravity = np.array([jdict['processed_gravity_x'],jdict['processed_gravity_y'],jdict['processed_gravity_z']]).T;
    proc_attitude = np.array([jdict['processed_roll'],jdict['processed_pitch'],jdict['processed_yaw']]).T;

    proc_timeref = np.array(jdict['processed_timeref']).T;

    location = np.array([jdict['location_timestamp'],jdict['location_latitude'],jdict['location_longitude'],\
                             jdict['location_altitude'],jdict['location_speed'],\
                             jdict['location_horizontal_accuracy'],jdict['location_vertical_accuracy']]).T;
    
    lf_data = jdict['low_frequency'];
        
    return (raw_acc,raw_magnet,raw_gyro,proc_timeref,proc_acc,proc_magnet,proc_gyro,proc_gravity,proc_attitude,location,lf_data);

def read_datafile_json_list(hf_file):
    # open the file for reading
    fid = open(hf_file, "r");
    jlist = json.load(fid);
    fid.close();

    # load data into arrays:
    acc = np.zeros((len(jlist),3));
    magnet = np.zeros((len(jlist),3));
    gyro = np.zeros((len(jlist),3));
    gps = np.zeros((len(jlist),3));
    
    lf_data = {};

    #loop through json and write data:
    for j in range(len(jlist)):
        # Read the fields expected in every sample:
        acc[j,0] = jlist[j]['acc_x'];
        acc[j,1] = jlist[j]['acc_y'];
        acc[j,2] = jlist[j]['acc_z'];
        magnet[j,0] = jlist[j]['magnet_x'];
        magnet[j,1] = jlist[j]['magnet_y'];
        magnet[j,2] = jlist[j]['magnet_z'];
        gyro[j,0] = jlist[j]['gyro_x'];
        gyro[j,1] = jlist[j]['gyro_y'];
        gyro[j,2] = jlist[j]['gyro_z'];
        gps[j,0] = jlist[j]['lat'];
        gps[j,1] = jlist[j]['long'];
        gps[j,2] = jlist[j]['speed'];

        # Read the fields expected only in part of the samples:
        for field_name in g__lf_fields:
            lf_field = 'lf_%s' % field_name;
            
            if lf_field in jlist[j]:
                # Make sure this field is in the output dictionary:
                if lf_field not in lf_data:
                    lf_data[lf_field] = [];
                    pass;

                # Add the new found value:
                lf_val = jlist[j][lf_field];
                lf_data[lf_field].append(lf_val);
                pass; # end if lf_filed...
            pass; # end for field_name...
        pass;
        
    return (acc,magnet,gyro,gps,lf_data);


def main():

#    uuid = 'F1F08EA2-44A0-444D-9E2E-821A22D99804';

    uuids = [];
    fid = file('real_uuids.list','rb');
    for line in fid:
        line = line.strip();
        if line.startswith('#'):
            continue;

        uuids.append(line);
        pass;
    fid.close();

    skip_existing = False;
    for uuid in uuids:
        print "="*20;
        print "=== uuid: %s" % uuid;
        collect_all_instances_of_uuid(uuid,skip_existing);
        pass;

    return;

if __name__ == "__main__":
    main();


