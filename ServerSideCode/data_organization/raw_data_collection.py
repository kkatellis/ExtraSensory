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

import unpacking_data;
import user_statistics;

import pdb;

fid                 = file('env_params.json','rb');
g__env_params       = json.load(fid);
fid.close();
g__output_superdir  = g__env_params['data_superdir'];
g__input_superdir   = g__env_params['zip_superdir'];


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

    has_data = unpacking_data.unpack_data_instance(input_zip_file,instance_out_dir);
    if not has_data:
        print "-- no HF data file";
        # Delete any unpacked files from the zip:
        for unpacked_file in glob.glob(instance_out_dir + '/*'):
            os.remove(unpacked_file);
            pass;
        # Delete the newly created dir:
        os.rmdir(instance_out_dir);
        print "--- Removed dir: %s" % instance_out_dir;
        return False;

    copy_feedback_file(input_instance_dir,instance_out_dir);
    

    return True;

def copy_feedback_file(input_instance_dir,instance_out_dir):
    # If there is a label-feedback file, copy it:
    feedback_file = os.path.join(input_instance_dir,'feedback');
    out_feedback_file = os.path.join(instance_out_dir,'feedback');
    if os.path.exists(feedback_file):
        shutil.copyfile(feedback_file,out_feedback_file);
        print "++ Copied feedback file";
        pass;

    return;



def main():

    uuids   = user_statistics.read_subjects_uuids();

    skip_existing = True;
    for uuid in uuids:
        print "="*20;
        print "=== uuid: '%s'" % uuid;
        collect_all_instances_of_uuid(uuid,skip_existing);
        pass;

    return;

if __name__ == "__main__":
    main();


