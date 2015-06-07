'''
raw_data_collection.py

This module is to organize the collected data from ExtraSensory app.
The collected measurements are sent in a zip file (sometimes including also labels from active-feedback) and the labels can also be provided through the api.

This module can help collect them together to an organized directory per user.
This is to be used offline, unrelated to the web service.
--------------------------------------------------------------------------
Written by Yonatan Vaizman. October 2014.
'''
import traceback;
import os;
import glob;
import fnmatch;
import subprocess;
import json;
import zipfile;
import numpy as np;
import shutil;

import pdb;

##g__output_superdir = '/Users/yonatan/Documents/data_collection/uuids';
##g__input_superdir = '/Library/WebServer/Documents/rmw/user_input';
g__output_superdir = 'data/raw_data';
g__input_superdir = 'data/raw_zipped_data';


def collect_all_instances_of_uuid(uuid,skip_existing):
    input_uuid_dir = os.path.join(g__input_superdir,uuid);
    if not os.path.exists(input_uuid_dir):
        return;

    for timestamp in os.listdir(input_uuid_dir):
        print timestamp;
        try:
            collect_single_instance(uuid,timestamp,skip_existing);
            pass;
        except Exception as ex:
            print "!!! Error for timestamp ", timestamp;
            traceback.print_exc();
#            raise ex;
            pass;

        pass; # end for filename...

    return;

def collect_single_instance(uuid,timestamp,skip_existing):
    input_uuid_dir = os.path.join(g__input_superdir,uuid);
    if not os.path.exists(input_uuid_dir):
        return False;

    input_instance_dir = os.path.join(input_uuid_dir,timestamp);
    if not os.path.exists(input_instance_dir):
        return False;

    # First check if there is any source of data for this uuid and timestamp:
    input_zip_filename = '%s-%s.zip' % (timestamp,uuid);
    input_zip_file = os.path.join(input_instance_dir,input_zip_filename);
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
        # Delete any unpacked files from the zip:
        for unpacked_file in glob.glob(instance_out_dir + '/*'):
            os.remove(unpacked_file);
            pass;
        # Delete the newly created dir:
        os.rmdir(instance_out_dir);
        print "--- Removed dir: %s" % instance_out_dir;
        return False;

    # If there is a label-feedback file, copy it:
    feedback_file = os.path.join(input_instance_dir,'feedback');
    out_feedback_file = os.path.join(instance_out_dir,'feedback');
    if os.path.exists(feedback_file):
        shutil.copyfile(feedback_file,out_feedback_file);
        print "++ Copied feedback file";
        pass;
    else:
        # Check if there are labels from active feedback:
        active_label_file = os.path.join(instance_out_dir,'label.txt');
        if os.path.exists(active_label_file):
            out_jlist = analyze_active_labels_file(active_label_file,instance_out_dir,uuid,timestamp);
            fid = file(out_feedback_file,'wb');
            json.dump(out_jlist,fid);
            fid.close();
            print "++ Saved labels from active feedback file into file 'feedback'";
            pass; # end if exists active_label_file
        else:
            print "-- No feedback file and no active label.txt file";
            pass; # end else (if exists active_label_file)

        pass; # end else (if exists feedback_file)

    # Read the measurements file and save the different modalities to files:
    (raw_acc,raw_magnet,raw_gyro,proc_timeref,proc_acc,proc_magnet,proc_gyro,proc_gravity,proc_attitude,location,lf_data,watch_acc,location_quick,proc_rotation) = read_datafile(hf_file);

    np.savetxt(os.path.join(instance_out_dir,'m_raw_acc.dat'),raw_acc);
    np.savetxt(os.path.join(instance_out_dir,'m_raw_magnet.dat'),raw_magnet);
    np.savetxt(os.path.join(instance_out_dir,'m_raw_gyro.dat'),raw_gyro);

    np.savetxt(os.path.join(instance_out_dir,'m_proc_timeref.dat'),proc_timeref);

    np.savetxt(os.path.join(instance_out_dir,'m_proc_acc.dat'),proc_acc);
    np.savetxt(os.path.join(instance_out_dir,'m_proc_magnet.dat'),proc_magnet);
    np.savetxt(os.path.join(instance_out_dir,'m_proc_gyro.dat'),proc_gyro);
    np.savetxt(os.path.join(instance_out_dir,'m_proc_gravity.dat'),proc_gravity);
    np.savetxt(os.path.join(instance_out_dir,'m_proc_attitude.dat'),proc_attitude);
    np.savetxt(os.path.join(instance_out_dir,'m_rotation.dat'),proc_rotation);
    
    np.savetxt(os.path.join(instance_out_dir,'m_location.dat'),location);
    np.savetxt(os.path.join(instance_out_dir,'m_watch_acc.dat'),watch_acc);
    
    lf_out_file = os.path.join(instance_out_dir,'m_lf_measurements.json');
    fid = open(lf_out_file,'wb');
    json.dump(lf_data,fid);
    fid.close();
    if len(lf_data) > 0:
        print "++ Created low-frequency measures file";
        pass;

    location_quick_out_file = os.path.join(instance_out_dir,'m_location_quick_features.json');
    fid = open(location_quick_out_file,'wb');
    json.dump(location_quick,fid);
    fid.close();

    return True;

def analyze_active_labels_file(active_label_file,instance_out_dir,uuid,timestamp):
    fid = file(active_label_file,'rb');
    in_jlist = json.load(fid);
    fid.close();

    out_jlist = {'active_feedback':'true','uuid':uuid,'timestamp':timestamp};

    out_jlist['corrected_activity'] = in_jlist['mainActivity'];

    if 'secondaryActivities' in in_jlist:
        out_jlist['secondary_activities'] = in_jlist['secondaryActivities'];
        pass;
    
    if 'mood' in in_jlist:
        out_jlist['mood'] = in_jlist['mood'];
        pass;

    if 'moods' in in_jlist:
        out_jlist['moods'] = in_jlist['moods'];
        pass;

    print "++ Analyzed active feedback file.";

    return out_jlist;

def join_data_fields_to_array(jdict,field_names):

    try:
        nf = len(field_names);
        field_dims = [];
        for (fi,name) in enumerate(field_names):
            if name in jdict:
                field_dims.append(len(jdict[name]));
                pass;
            else:
                field_dims.append(-1);
                pass;
            pass;

        data_dim = max(field_dims);
        if data_dim < 0:
            # (If all fields are missing)
            raise Exception;

        # Prepare a row of nan for missing fields:
        nan_row = [];
        for ii in range(data_dim):
            nan_row.append(np.nan);
            pass;
        
        list_of_rows = [];
        for name in field_names:
            if name in jdict:
                list_of_rows.append(jdict[name]);
                pass;
            else:
                list_of_rows.append(nan_row);
                pass;
            pass;
        arr = np.array(list_of_rows).T;
        pass;
    except:
        arr = np.array([np.nan]);
        pass;

    return arr;

def read_datafile(hf_file):
    # open the file for reading
    fid = open(hf_file, "r");
    jdict = json.load(fid);
    fid.close();

    raw_acc = join_data_fields_to_array(jdict,['raw_acc_timeref','raw_acc_x','raw_acc_y','raw_acc_z']);
    raw_gyro = join_data_fields_to_array(jdict,['raw_gyro_timeref','raw_gyro_x','raw_gyro_y','raw_gyro_z']);
    raw_magnet = join_data_fields_to_array(jdict,['raw_magnet_timeref','raw_magnet_x','raw_magnet_y','raw_magnet_z']);

    proc_acc_time_field = 'processed_user_acc_timeref' if 'processed_user_acc_timeref' in jdict else 'processed_timeref';
    proc_acc = join_data_fields_to_array(jdict,[proc_acc_time_field,'processed_user_acc_x','processed_user_acc_y','processed_user_acc_z']);
    proc_magnet_time_field = 'processed_magnet_timeref' if 'processed_magnet_timeref' in jdict else 'processed_timeref';
    proc_magnet = join_data_fields_to_array(jdict,[proc_magnet_time_field,'processed_magnet_x','processed_magnet_y','processed_magnet_z']);
    proc_gyro_time_field = 'processed_gyro_timeref' if 'processed_gyro_timeref' in jdict else 'processed_timeref';
    proc_gyro = join_data_fields_to_array(jdict,[proc_gyro_time_field,'processed_gyro_x','processed_gyro_y','processed_gyro_z']);

    proc_gravity_time_field = 'processed_gravity_timeref' if 'processed_gravity_timeref' in jdict else 'processed_timeref';
    proc_gravity = join_data_fields_to_array(jdict,[proc_gravity_time_field,'processed_gravity_x','processed_gravity_y','processed_gravity_z']);
    # Iphone attitude:
    proc_attitude = join_data_fields_to_array(jdict,['processed_timeref','processed_roll','processed_pitch','processed_yaw']);
    # Android attitude:
    proc_rotation = join_data_fields_to_array(jdict,['processed_rotation_vector_timeref','processed_rotation_vector_x','processed_rotation_vector_y','processed_rotation_vector_z','processed_rotation_vector_cosine','processed_rotation_vector_accuracy']);

    proc_timeref = join_data_fields_to_array(jdict,['processed_timeref']);

    loc_time_field = 'location_timeref' if 'location_timeref' in jdict else 'location_timestamp';
    location = join_data_fields_to_array(jdict,[loc_time_field,'location_latitude','location_longitude',\
                                              'location_altitude','location_speed',\
                                              'location_horizontal_accuracy','location_vertical_accuracy']);

    watch_acc = join_data_fields_to_array(jdict,['raw_watch_acc_x','raw_watch_acc_y','raw_watch_acc_z']);
    
    if 'low_frequency' in jdict:
        lf_data = jdict['low_frequency'];
        pass;
    else:
        lf_data = {};
        pass;

    if 'location_quick_features' in jdict:
        location_quick = jdict['location_quick_features'];
        pass;
    else:
        location_quick = {};
        pass;
    
    return (raw_acc,raw_magnet,raw_gyro,proc_timeref,proc_acc,proc_magnet,proc_gyro,proc_gravity,proc_attitude,location,lf_data,watch_acc,location_quick,proc_rotation);


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

    skip_existing = True;
    for uuid in uuids:
        print "="*20;
        print "=== uuid: %s" % uuid;
        collect_all_instances_of_uuid(uuid,skip_existing);
        pass;

    return;

if __name__ == "__main__":
    main();


