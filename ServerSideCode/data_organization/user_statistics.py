'''
user_statistics.py

This module is to calculate statistics per user, including how many instances
were collected from the user and the distributions of labels provided by the user.
--------------------------------------------------------------------------
Written by Yonatan Vaizman. November 2014.
'''
import os;
import os.path;
import json;
import numpy;
import pdb;


g__data_superdir            = 'uuids';

def get_instance_labels(instance_dir):
    feedback_file           = os.path.join(instance_dir,'feedback');
    if not os.path.exists(feedback_file):
        return (None,None,None);

    fid = file(feedback_file,'rb');
    feedback                = json.load(fid);
    fid.close();

    main_activity           = feedback['corrected_activity'];
    
    secondary_activities    = [];
    for act in feedback['secondary_activities']:
        if len(act) > 0:
            secondary_activities.append(act);
            pass; # end if len(act)....
        pass; # end for act...

    mood                    = feedback['mood'];
    if (mood == '(NULL)'):
        mood                = None;
        pass;

    return (main_activity,secondary_activities,mood);

def raise_key_count(count_dict,key):
    if key not in count_dict:
        count_dict[key]     = 1;
        pass;
    else:
        count_dict[key]     = count_dict[key] + 1;
        pass;
    
    return count_dict;

def calc_entropy(count_dict):
    counts                  = numpy.array(count_dict.values()).astype(float);
    tot                     = numpy.sum(counts).astype(float);
    if tot <= 0:
        return 0.;

    probs                   = counts / tot;
    log_probs               = numpy.log2(probs);
    plogp                   = probs*log_probs;

    entropy                 = - numpy.sum(plogp);

    return entropy;

def statistics_per_user(uuid):
    uuid_dir = os.path.join(g__data_superdir,uuid);

    instance_count          = 0;
    labeled_count           = 0;
    
    main_counts             = {};
    secondary_counts        = {};
    mood_counts             = {};
    
    for dirname in os.listdir(uuid_dir):
        instance_dir = os.path.join(uuid_dir,dirname);
        if os.path.isdir(instance_dir):
            instance_count  = instance_count + 1;
            
            (main_activity,\
             secondary_activities,\
             mood)          = get_instance_labels(instance_dir);

            if main_activity == None:
                continue;

            labeled_count   = labeled_count + 1;
            
            main_counts     = raise_key_count(main_counts,main_activity);
            for sec_act in secondary_activities:
                secondary_counts    = raise_key_count(secondary_counts,sec_act);
                pass;
            if mood != None:
                mood_counts = raise_key_count(mood_counts,mood);
                pass;
            
            pass; # end if isdir...
        
        pass; # end for dirname...

    uuid_stats                      = {};
    uuid_stats['instance_count']    = instance_count;
    uuid_stats['labeled_count']     = labeled_count;
    uuid_stats['main_counts']       = main_counts;
    uuid_stats['secondary_counts']  = secondary_counts;
    uuid_stats['mood_counts']       = mood_counts;

    uuid_stats['main_entropy']      = calc_entropy(main_counts);
    uuid_stats['secondary_entropy'] = calc_entropy(secondary_counts);
    uuid_stats['mood_entropy']      = calc_entropy(mood_counts);

    pdb.set_trace();
    return uuid_stats;


def reward_for_participation(user_stats):
    

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
        uuid_stats          = statistics_per_user(uuid);

        pdb.set_trace();
        pass;

    return;

if __name__ == "__main__":
    main();


