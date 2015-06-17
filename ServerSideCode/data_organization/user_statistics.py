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


g__data_superdir            = 'data/raw_data';
g__dont_remember            = "DON'T_REMEMBER";

def get_instance_labels(instance_dir):
    feedback_file           = os.path.join(instance_dir,'feedback');
    if not os.path.exists(feedback_file):
        return (None,None,None);

    fid = file(feedback_file,'rb');
    feedback_list           = json.load(fid);
    fid.close();
    # Get the most up-to-date feedback:
    if (type(feedback_list) == list):
        feedback            = feedback_list[-1];
        pass;
    else:
        feedback            = feedback_list;
        pass;

    main_activity           = feedback['corrected_activity'];
    
    secondary_activities    = [];
    if 'secondary_activities' in feedback:
        for act in feedback['secondary_activities']:
            if len(act) > 0:
                secondary_activities.append(act);
                pass; # end if len(act)....
            pass; # end for act...
        pass; # end if secondary in feedback...

    moods                   = [];
    if 'moods' in feedback:
        for mood in feedback['moods']:
            if len(mood) > 0:
                moods.append(mood);
                pass; # end if len(mood)...
            pass; # end for mood
        pass; # end if moods in feedback...
    
    return (main_activity,secondary_activities,moods);

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
    global g__dont_remember;
    
    uuid_dir = os.path.join(g__data_superdir,uuid);

    instance_count          = 0;
    labeled_count           = 0;
    main_label_count        = 0;
    sec_1or2_count          = 0;
    sec_more_than2_count    = 0;
    mood_count              = 0;
    
    main_counts             = {};
    secondary_counts        = {};
    mood_counts             = {};
    
    for dirname in os.listdir(uuid_dir):
        instance_dir = os.path.join(uuid_dir,dirname);
        if os.path.isdir(instance_dir):
            instance_count  = instance_count + 1;
            
            (main_activity,\
             secondary_activities,\
             moods)         = get_instance_labels(instance_dir);

            if main_activity == None:
                continue;
            
            # update general counts:
            labeled_count   = labeled_count + 1;
            if main_activity != g__dont_remember:
                main_label_count    = main_label_count + 1;
                pass;
            else:
#                print "detected don't remember label: ", main_activity;
                pass;

            if len(secondary_activities) > 0:
                if len(secondary_activities) > 2:
                    sec_more_than2_count    = sec_more_than2_count + 1;
                    pass;
                else:
                    sec_1or2_count          = sec_1or2_count + 1;
                    pass;
                pass;

            if len(moods) > 0:
                mood_count          = mood_count + 1;
                pass;

            # update label-specific counts:
            main_counts     = raise_key_count(main_counts,main_activity);
            for sec_act in secondary_activities:
                secondary_counts    = raise_key_count(secondary_counts,sec_act);
                pass;
            for mood in moods:
                mood_counts = raise_key_count(mood_counts,mood);
                pass;
            
            pass; # end if isdir...
        
        pass; # end for dirname...

    uuid_stats                      = {};
    uuid_stats['instance_count']    = instance_count;
    uuid_stats['labeled_count']     = labeled_count;
    uuid_stats['main_label_count']  = main_label_count;
    uuid_stats['sec_1or2_count']    = sec_1or2_count;
    uuid_stats['sec_more_than2_count']  = sec_more_than2_count;
    uuid_stats['mood_count']        = mood_count;

    
    uuid_stats['main_counts']       = main_counts;
    uuid_stats['secondary_counts']  = secondary_counts;
    uuid_stats['mood_counts']       = mood_counts;

    uuid_stats['main_entropy']      = calc_entropy(main_counts);
    uuid_stats['secondary_entropy'] = calc_entropy(secondary_counts);
    uuid_stats['mood_entropy']      = calc_entropy(mood_counts);

    return uuid_stats;


def reward_for_participation(user_stats):
    main_c      = user_stats['main_label_count'];
    sec12       = user_stats['sec_1or2_count'];
    sec_over2   = user_stats['sec_more_than2_count'];
    mood_c      = user_stats['mood_count'];

    main_rate   = 0.0025;
    sec12_rate  = 0.005;
    sec_ex_rate = 0.0075;
    mood_rate   = 0.0025;

    main_cost   = main_rate * main_c;
    sec12_cost  = sec12_rate * sec12;
    sec_ex_cost = sec_ex_rate * sec_over2;
    mood_cost   = mood_rate * mood_c;
    
    total_cost  = main_cost + sec12_cost + sec_ex_cost + mood_cost;

    print("label:\t|\tcount:\t|\tcost ($):");
    print("-"*20);
    print("main\t|\t%d:\t|\t%f" % (main_c,main_cost));
    print("sec<=2\t|\t%d\t|\t%f" % (sec12,sec12_cost));
    print("sec>2\t|\t%d\t|\t%f" % (sec_over2,sec_ex_cost));
    print("mood\t|\t%d\t|\t%f" % (mood_c,mood_cost));
    print("-"*20);
    print("total:\t|\t \t|\t%f" % (total_cost));
    print("="*30);

    return total_cost;

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
        reward_for_participation(uuid_stats);
        
        pdb.set_trace();
        pass;

    return;

if __name__ == "__main__":
    main();


