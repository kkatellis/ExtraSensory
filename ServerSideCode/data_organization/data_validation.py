'''
data_validation.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. November 2014.
'''
import os;
import os.path;
import json;
import numpy;
import pdb;


g__data_superdir            = 'uuids';


def location_updates_per_user(uuid):
    uuid_dir = os.path.join(g__data_superdir,uuid);
    
    for dirname in os.listdir(uuid_dir):
        instance_dir = os.path.join(uuid_dir,dirname);
        instance_timestamp          = int(dirname);
        if not os.path.isdir(instance_dir):
            continue;

        location_file               = os.path.join(instance_dir,'m_location');
        if not os.path.exists(location_file):
            continue;

        location_updates            = numpy.genfromtxt(location_file);
        if len(location_updates.shape) > 1:
            timestamps              = location_updates[:,0].astype(int);
            pass;
        else:
            timestamps              = [location_updates[0].astype(int)];
            pass;
        unique_timestamps           = set(timestamps);
        num_timepoints              = len(unique_timestamps);
        print "Instance %s has %d timepoints that have location info." % (dirname,num_timepoints);
        if num_timepoints > 0:
            #print unique_timestamps;
            print numpy.array(list(unique_timestamps))-instance_timestamp;
            pass;
        
        pass; # end for dirname...

    return;

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

    for uuid in uuids:
        print "="*20;
        print "=== uuid: %s" % uuid;
        location_updates_per_user(uuid);

        pdb.set_trace();
        pass;

    return;

if __name__ == "__main__":
    main();


