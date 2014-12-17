#!/usr/bin/env python
'''
CREATED:July 2012 by Yonatan Vaizman <yvaizman@eng.ucsd.edu>

This module handles annotation and retrieval performance evaluations.
'''

import numpy;
import pylab;
pylab.ion();


def get_performance_measures(affinity_mat,ground_truth_labels,desired_measures = None,N_annotations_per_song = 10):
    # Make sure the matrices are in real number representation,
    # to avoide numeric mistakes:
    affinity_mat        = affinity_mat.astype(float);
    ground_truth_labels = ground_truth_labels.astype(float);
    
    if desired_measures == None:
        desired_measures = ['annotation','auc','p10','mean_ap'];
        
    scores = {};
    if 'precision' in desired_measures or \
       'recall' in desired_measures or \
       'f' in desired_measures or \
       'annotation' in desired_measures:
        (precision,recall,f,\
         precision_per_tag,recall_per_tag,f_per_tag) = get_annotation_measures(\
             affinity_mat,ground_truth_labels,N_annotations_per_song);
        scores['precision'] = precision;
        scores['recall']    = recall;
        scores['f']         = f;
        scores['precision_per_tag']     = precision_per_tag;
        scores['recall_per_tag']        = recall_per_tag;
        scores['f_per_tag']             = f_per_tag;
                                                                        
    if 'auc' in desired_measures or \
       'p10' in desired_measures or \
       'mean_ap' in desired_measures:
        retrieval_stuff = get_ROC_curve_plus(\
            affinity_mat,ground_truth_labels);
        
    if 'auc' in desired_measures:
        (auc,auc_per_tag)       = get_auc(retrieval_stuff['true_pos_rate'],\
                                          retrieval_stuff['false_pos_rate']);
        scores['auc']           = auc;
        scores['auc_per_tag']   = auc_per_tag;

    if 'p10' in desired_measures:
        (p10,p10_per_tag)       = get_p10(retrieval_stuff['precision_at_top']);
        scores['p10']           = p10;
        scores['p10_per_tag']   = p10_per_tag;

    if 'mean_ap' in desired_measures:
        (mean_ap,ap_per_tag)    = get_map(retrieval_stuff['precision_at_top'],\
                                          retrieval_stuff['labels_ordered'],\
                                          retrieval_stuff['num_gt_pos']);
        scores['mean_ap']       = mean_ap;
        scores['ap_per_tag']    = ap_per_tag;
        
    return scores;


def get_N_top_most_values_indices(values,N):
    enumeration = enumerate(values);
    sorted_enumeration = sorted(enumeration,key=lambda item:item[1]);
    # Now we can get the indices of the sorted items (from smaller to larger):
    sorted_inds = [i[0] for i in sorted_enumeration];
    # And now we can take the N last indices:
    top_N_inds = sorted_inds[-N:];
    
    return top_N_inds;

def fix_nan_values(values,fixing_values):
    nan_values = numpy.isnan(values);
    values[nan_values] = fixing_values[nan_values];

    return values;

def get_annotation_measures(affinity_mat,ground_truth_labels,N_annotations_per_song):
    '''
    Calculate annotation measures in a per-tag way, and the mean over tags:
    precision, recall and F-score.
    '''

    (song_n,tag_n) = affinity_mat.shape;
    
    # Calculate tag-priors (to be used later):
    tag_prior   = sum(ground_truth_labels);
    tag_prior   = tag_prior / sum(tag_prior);
    
    # Annotate each song with the top N tags on its affinity vector:
    N = N_annotations_per_song; ##10;
    machine_annotation_mat = numpy.zeros(affinity_mat.shape);
    for song_i in range(song_n):
        annotated_tag_inds = get_N_top_most_values_indices(\
            affinity_mat[song_i,:],N);
        machine_annotation_mat[song_i,annotated_tag_inds] = 1;

    # Mark the correct annotations (where machine annotated and also ground truth has annotation):
    correct_annotation_mat = machine_annotation_mat * ground_truth_labels;

    # For each tag count: #machine annotated, #gt annotated, #correct annotated:
    num_machine_ann = numpy.sum(machine_annotation_mat,axis=0);    
    num_gt_ann      = numpy.sum(ground_truth_labels,axis=0);    
    num_correct_ann = numpy.sum(correct_annotation_mat,axis=0);

    # Now for each tag calculate: precision, recall and F-score:
    precision_per_tag   = num_correct_ann / num_machine_ann;
    precision_per_tag   = fix_nan_values(precision_per_tag,tag_prior);
    recall_per_tag      = num_correct_ann / num_gt_ann;
    recall_per_tag      = fix_nan_values(recall_per_tag,tag_prior);
    f_per_tag           = 2 * \
                          (precision_per_tag * recall_per_tag) / \
                          (precision_per_tag + recall_per_tag);
    f_per_tag[numpy.isnan(f_per_tag)]   = 0;

    # Calculate means over tags:
    precision   = numpy.mean(precision_per_tag);
    recall      = numpy.mean(recall_per_tag);
    f           = numpy.mean(f_per_tag);

    return (precision,recall,f,precision_per_tag,recall_per_tag,f_per_tag);

def get_map(precision_at_top,labels_ordered,num_gt_pos):
    '''
    Calculate the Average Precision for each tag,
    and the Mean Average Precision (mean over tags).
    The AP per tag is the average, over all positions of
    tag-relevant songs in the retrieval order, of the precision
    in these positions.
    '''

    (song_n,tag_n) = labels_ordered.shape;
    
    # Multiply the precision values by the indication at each position
    # of whether this position's item is relevant for the tag or not:
    prec_in_relevant_positions  = precision_at_top * labels_ordered;

    # Sum up these relevant precision values for each tag:
    prec_sums   = numpy.reshape(numpy.sum(prec_in_relevant_positions,axis=0),(1,tag_n));

    # And divide by the number of relevant positions for each tag (number of relevant songs):
    ap_per_tag  = prec_sums / num_gt_pos.astype('float');

    # And mean over tags:
    slicer      = good_inds_slicer(ap_per_tag);
    mean_ap     = numpy.mean(ap_per_tag[slicer]);

    return (mean_ap,ap_per_tag);
    
def get_p10(precision_at_top):
    '''
    Calculate the precision at top 10 retrieved songs per each tag,
    and the mean p@10 over all tags
    '''

    (song_n,tag_n) = precision_at_top.shape;

    if song_n < 10:
        threshold_index = song_n - 1;
    else:
        threshold_index = 9;
        
    p10_per_tag     = precision_at_top[threshold_index,:];
    slicer          = good_inds_slicer(p10_per_tag);
    p10             = numpy.mean(p10_per_tag[slicer]);

    return (p10,p10_per_tag);
    
def get_auc(true_pos_rate,false_pos_rate,display_roc=None):
    '''
    The the AUC (Area Under Curve), referring to the ROC curve
    (Receiver Operating Curve), that displayes the tradeoff between false positive
    rate and false negative rate, for a binary classification.

    affinity_mat:   (song_n x tag_n) matrix of numeric affinity values
                    (possibly probability values). For each song (row) and tag (column)
                    The affinity of the song to the tag.
    ground_truth_labels:    (song_n x 1) binary values: 0=false, 1=true.

    For each tag (column) this function computes the ROC curve of classifying
    the instances according to the affinity values as decision values.
    It returns the area under the curve for each tag, and the mean over tags.
    '''

    if (display_roc != None and display_roc):
        pylab.figure();
        pylab.plot(false_pos_rate,true_pos_rate,'o-');
        pylab.xlabel('FPR');
        pylab.ylabel('TPR');
        pylab.show();
        
    # The ROC curve is the curve of true positive rate (y-axis) vs. false positive rate (x-axis).
    # To calculate the area under the curve, we'll sum the areas of rectangular
    # steps:
    steps_widths    = false_pos_rate[1:,:] - false_pos_rate[:-1,:];
    steps_hights    = true_pos_rate[1:,:];
    steps_areas     = steps_widths * steps_hights;

    auc_per_tag = numpy.sum(steps_areas,axis=0);
    slicer      = good_inds_slicer(auc_per_tag);
    auc         = numpy.mean(auc_per_tag[slicer]);

    return (auc,auc_per_tag);

def good_inds_slicer(vector):
    slicer = ((1+numpy.isnan(vector))%2).astype(bool);
    return slicer;

def get_ROC_curve_plus(affinity_mat,ground_truth_labels):
    '''
    Calculate for each tag (column) the ROC curve for that tag
    (meaning a sequence of false positive rates and true positive rates),
    plus values of true positive rates at each position for each tag,
    and other useful calculations over the retrieval.
    '''
    (song_n,tag_n) = affinity_mat.shape;
    ground_truth_labels = numpy.reshape(ground_truth_labels.astype(int),(song_n,tag_n));

    # How many positive and negative instances are there for each tag (ground truth):
    num_gt_pos = sum(ground_truth_labels);
    num_gt_neg = song_n - num_gt_pos;

    # For each tag, order the gound truth labels according to the order
    # of the instances (songs) as sorted from large affinity to small:
    labels_ordered = numpy.zeros((song_n,0));
    for tag_i in range(tag_n):
        tag_labels_ordered = get_tag_ordered_labels(\
            affinity_mat[:,tag_i],ground_truth_labels[:,tag_i]);
        
        labels_ordered = numpy.concatenate((labels_ordered,tag_labels_ordered),axis=1);

    oposite_labels_ordered = (labels_ordered + 1) % 2;

    # Now see how many true positives (items in top of list that should be there)
    # and false positives (items in top of list that shouldn't be there)
    # there are in every threshold over the decision values:
    num_true_pos    = numpy.cumsum(labels_ordered,axis=0);
    num_false_pos   = numpy.cumsum(oposite_labels_ordered,axis=0);

    # Calculate the true positive rate (recall) and false positive rate in every threshold:
    true_pos_rate   = num_true_pos / num_gt_pos.astype(float);
    false_pos_rate  = num_false_pos / num_gt_neg.astype(float);

    # While we already calculated the retrieval order,
    # lets calculate the precision (num true pos / num machine-annotated as pos):
    num_over_threshold  = numpy.reshape(numpy.arange(1,song_n+1),(song_n,1));
    precision_at_top    = num_true_pos / num_over_threshold.astype(float);

    # Make sure the output results are in the correct shape:
    true_pos_rate = numpy.reshape(true_pos_rate,(song_n,tag_n));
    false_pos_rate = numpy.reshape(false_pos_rate,(song_n,tag_n));
    precision_at_top = numpy.reshape(precision_at_top,(song_n,tag_n));

    retrieval_stuff = {'true_pos_rate':true_pos_rate,\
                       'false_pos_rate':false_pos_rate,\
                       'precision_at_top':precision_at_top,\
                       'labels_ordered':labels_ordered,\
                       'num_gt_pos':num_gt_pos};
    return retrieval_stuff;

def get_tag_ordered_labels(affinity_vec,labels_vec):
    '''
    Order the tag's ground truth labels according to descending order
    of the decision values (affinity values) of the song instances.
    '''

    if numpy.var(affinity_vec) <= 0.0:
        print "degenerate classifier";
        # Then the classifier is degenerate
        # And we can order the labels in any way, since all the item have same decision value:
        ordered_labels = numpy.copy(labels_vec);
        # Lets order them in the worst possible order, from small label to large:
        ordered_labels = numpy.array(sorted(ordered_labels));
        pass;
    else:
        # sort the songs according to affinity value,
        # from large to small:
        inds_and_vals = enumerate(affinity_vec);
        sorted_inds_and_vals = sorted(\
            inds_and_vals,key = lambda x:x[1],reverse=True);
        sorted_inds = [pair[0] for pair in sorted_inds_and_vals];

        # Now arrange the ground truch labels in the order of the arranged songs:
        ordered_labels = labels_vec[sorted_inds];

        pass;

    n = len(ordered_labels);
    ordered_labels = numpy.reshape(ordered_labels,(n,1));

    return (ordered_labels);

def summarize_scores_over_folds(scores_per_fold,calculate_standard_deviation=False,add_tag_names=True):

    k = len(scores_per_fold); # number of folds

    precision_per_fold  = [];
    recall_per_fold     = [];
    f_per_fold          = [];
    auc_per_fold        = [];
    p10_per_fold        = [];
    map_per_fold        = [];
    tags_per_fold       = [];

    for fold_i in range(k):
        precision_per_fold.append(scores_per_fold[fold_i]['precision']);
        recall_per_fold.append(scores_per_fold[fold_i]['recall']);
        f_per_fold.append(scores_per_fold[fold_i]['f']);
        auc_per_fold.append(scores_per_fold[fold_i]['auc']);
        p10_per_fold.append(scores_per_fold[fold_i]['p10']);
        map_per_fold.append(scores_per_fold[fold_i]['mean_ap']);
        if add_tag_names:
            tags_per_fold.append(scores_per_fold[fold_i]['fold_tag_names']);

    scores = {\
        'precision':numpy.mean(precision_per_fold),\
        'precision_per_fold':precision_per_fold,\
        'recall':numpy.mean(recall_per_fold),\
        'recall_per_fold':recall_per_fold,\
        'f':numpy.mean(f_per_fold),\
        'f_per_fold':f_per_fold,\
        'auc':numpy.mean(auc_per_fold),\
        'auc_per_fold':auc_per_fold,\
        'p10':numpy.mean(p10_per_fold),\
        'p10_per_fold':p10_per_fold,\
        'map':numpy.mean(map_per_fold),\
        'map_per_fold':map_per_fold,\

        'scores_per_fold':scores_per_fold};

    if add_tag_names:
        scores['tags_per_fold'] = tags_per_fold;
        pass

    if calculate_standard_deviation:
        scores['precision_std']     = numpy.std(precision_per_fold);
        scores['recall_std']        = numpy.std(recall_per_fold);
        scores['f_std']             = numpy.std(f_per_fold);
        scores['auc_std']           = numpy.std(auc_per_fold);
        scores['p10_std']           = numpy.std(p10_per_fold);
        scores['map_std']           = numpy.std(map_per_fold);

    return scores;


def estimate_random_performance(ground_truth_labels,num_trials):

    print "Estimating random performance....";

    measures = ['precision','recall','f','auc','p10','mean_ap'];
    (song_n,tag_n)      = ground_truth_labels.shape;
    scores_per_measure  = {};
    
    for measure in measures:
        scores_per_measure[measure] = [];
        pass;

    for trial in range(num_trials):

        print "trial " + str(trial) + " out of " + str(num_trials);
        
        random_mat  = numpy.random.rand(song_n,tag_n);
        # Make it a valid affinity mat (each row - a song SMN):
        songSums                    = numpy.sum(random_mat,axis=1);
        songSums                    = numpy.reshape(songSums,(song_n,1));
        random_machine_affinity_mat = random_mat / songSums;

        trial_scores                = get_performance_measures(\
            random_machine_affinity_mat,ground_truth_labels);

        for measure in measures:
            scores_per_measure[measure].append(trial_scores[measure]);
            pass;

        pass;


    mean_per_measure    = {};
    std_per_measure     = {};
    for measure in measures:
        mean_per_measure[measure]   = numpy.mean(scores_per_measure[measure]);
        std_per_measure[measure]    = numpy.std(scores_per_measure[measure]);
        pass;
        
    return mean_per_measure,std_per_measure;


def main():
    # Try various examples of retrieval situations.

    desired_measures = ['auc','auc_per_tag','p10','p10_per_tag','mean_ap','ap_per_tag'];
    gt_labels = numpy.array([[1,0],[0,1],[1,0],[0,1],[1,0],[0,0]]);
    
    # Good retrieval:
    good_affinity = numpy.array([[10.0,4.0],[4.0,8.0],[12.0,5.0],[5.0,10.0],[7.0,1.0],[3.0,2.0]]);
    good_scores = get_performance_measures(good_affinity,gt_labels,desired_measures);
    
    # Really bad retrieval (retrieval machine orders in opposite order):
    bad_affinity = 1.0 / good_affinity;
    bad_scores = get_performance_measures(bad_affinity,gt_labels,desired_measures);

    # Medium retrieval:
    med_affinity = numpy.array([[1.0,4.0],[4.0,8.0],[12.0,5.0],[5.0,10.0],[7.0,2.0],[13.0,2.0]]);
    med_scores = get_performance_measures(med_affinity,gt_labels,desired_measures);

    1/0
    
if __name__ == "__main__":
    main();
