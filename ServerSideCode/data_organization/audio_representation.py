'''
audio_representation.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. August 2015.
'''

import os.path;
import random;
import json;
import numpy;
import sklearn.cluster;
import pickle;
import warnings;
import pdb;

import feature_codebooks;

fid                 = file('env_params.json','rb');
g__env_params       = json.load(fid);
fid.close();
g__data_superdir    = g__env_params['data_superdir'];


def get_dimension_of_audio_representation(audio_encoder):
    if audio_encoder == None:
        return 0;
    
    return audio_encoder['codebook'].shape[0];

def get_instance_audio_representation(instance_dir,audio_encoder):
    (feats,pre_norm)    = get_instance_audio_features(instance_dir);
    if feats.size <= 0:
        return numpy.nan*numpy.ones(get_dimension_of_audio_representation(audio_encoder));

    # Quantize each feature vector using the codebook:
    codebook            = audio_encoder['codebook'];
    tau                 = audio_encoder['tau'];
    code_mat            = feature_codebooks.vector_quantization(feats,codebook,tau);

    # Perform pooling:
    if len(code_mat) <= 1:
        # Then there is probably just a single frame that was quantized
        codeword_hist   = code_mat;
        pass;
    else:
        codeword_hist   = numpy.mean(code_mat,axis=0);
        pass;

    # Root compression (PPK transformation):
    rep_vec             = codeword_hist**0.5;
    # Make this a 1-d array:
    rep_vec             = numpy.squeeze(rep_vec);

    return rep_vec;


'''
Train an encoder that gets a time series of 13d MFCC features and produces a vectorial representation.

Input:
train_uuids: list of strings. The UUIDs of the train users to be used to train the encoder.
    The training procedure will go over the data directories of these UUIDs,
    and use the MFCC measurements from their instances.
audio_params: dict. Parameters to specify the encoder type and training mechanism. Including:
    audio_params['k']: scalar. The desired dimension of the encoding representation (number of centroids for VQ).
    audio_params['minibatch_size']: scalar. How many instances to include in each minibatch of the online learning algorithm.
    audio_params['encoder_params']: dict. Containing all the parameters you wish to include in the resulted encoder.
    

Output:
encoder: dict. The trained encoding parameters. Including:
    encoder['codebook']: (k x 39). k codewords (all unit norm) for VQ.
'''
def train_audio_encoder(train_uuids,audio_params):
    print "*" * 20;
    print "Training audio codebook...";
    # Prepare index for the training data to draw from:
    (uuid_inds,timestamps)      = prepare_train_set_index(train_uuids);
    n_instances                 = len(timestamps);
    inds                        = range(n_instances);
    random.shuffle(inds);

    k                           = audio_params['k'];
    minibatch_size              = audio_params['minibatch_size'];
    init_batch_size             = audio_params['init_batch_size'];
    n_minibatches               = audio_params['n_minibatches'];

    print "=== Initial k-means...";
    position                    = 0;
    (init_batch_feats,position) = sample_next_minibatch(train_uuids,uuid_inds,timestamps,inds,position,init_batch_size);
    codebook                    = feature_codebooks.initialize_k_means_codebook(init_batch_feats,k);

    for mini in range(n_minibatches):
        print "=== Online k-means. Minibatch %d" % mini;
        (minibatch_feats,position)  = sample_next_minibatch(train_uuids,uuid_inds,timestamps,inds,position,minibatch_size);
        codebook                    = feature_codebooks.k_means_iteration(codebook,minibatch_feats);
        pass; # end for mini...

    encoder                     = {'codebook':codebook};
    copied_params               = pickle.loads(pickle.dumps(audio_params['encoder_params']));
    for key in copied_params.keys():
        encoder[key]            = copied_params[key];
        pass;
    
    return encoder;


def sample_next_minibatch(train_uuids,uuid_inds,timestamps,inds,position,how_many):
    n_instances                 = len(inds);
    if position >= n_instances:
        # Adjust the starting position, in case we reached end of data:
        position                = position % n_instances;
        pass;
    stop                        = position + how_many;
    minibatch_inds              = inds[position:stop];
    if stop >= n_instances:
        # Then we only collected inds until the end of data.
        # Lets add more inds from the beginning of data:
        stop                    = stop % n_instances;
        added_inds              = inds[:stop];
        minibatch_inds.extend(added_inds);
        pass;

    feat_collection             = [None for ii in range(len(minibatch_inds))];
    pre_collection              = [None for ii in range(len(minibatch_inds))];
    for (ii,ind) in enumerate(minibatch_inds):
        uuid                    = train_uuids[uuid_inds[ind]];
        uuid_dir                = os.path.join(g__data_superdir,uuid);
        timestamp_str           = "%d" % timestamps[ind];
        instance_dir            = os.path.join(uuid_dir,timestamp_str);
        (feats,pre_norm)        = get_instance_audio_features(instance_dir);
        feat_collection[ii]     = feats;
        pre_collection[ii]      = pre_norm;
        pass; # end for (ii,ind)...

    minibatch_feats             = numpy.concatenate(tuple(feat_collection),axis=0);
    new_position                = stop;

    return (minibatch_feats,new_position);
    
    
'''
Read the audio (MFCC) features for a specific instance
and produce the appropriate raw feature vectors of it.
This includes taking windows of 3 consecutive 13d frames,
and normalizing each 39d feature vector to have unit norm.

In case the MFCC file doesn't exist, or has invalid data,
the returned features will have 0 rows.

Output:
feats: (T x 39) array. T windows (each is concatenation of 3 consecutive time frames), normalized.
pre_norm: (T x 39) array. Unnormalized features.
'''
def get_instance_audio_features(instance_dir):
    raw_d                       = 13;
    out_d                       = raw_d*3;
    empty_features              = numpy.zeros((0,out_d));
    mfcc_file                   = os.path.join(instance_dir,'sound.mfcc');
    if not os.path.exists(mfcc_file):
        return (empty_features,empty_features);

    with warnings.catch_warnings():
        warnings.simplefilter("ignore");
        mfcc                        = numpy.genfromtxt(mfcc_file,delimiter=',');
        pass;
    
    if len(mfcc.shape) != 2:
        return (empty_features,empty_features);

    (T,d)                       = mfcc.shape;
    if d == 14:
        mfcc                    = mfcc[:,:-1];
        d                       = mfcc.shape[1];
        pass;
    if d != 13:
        return (empty_features,empty_features);

    if T < 3:
        return (empty_features,empty_features);

    if numpy.any(numpy.isnan(mfcc)) or numpy.any(numpy.isinf(mfcc)):
        return (empty_features,empty_features);
    
    # Get windows of 3 frames:
    pre_norm                    = numpy.concatenate((mfcc[:-2,:],mfcc[1:-1,:],mfcc[2:,:]),axis=1);
    # Normalize each feature vector to have unit L2-norm:
    feats                       = normalize_feature_vectors(pre_norm);

    return (feats,pre_norm);

def normalize_feature_vectors(pre_norm_feats):
    norms                       = (numpy.sum(pre_norm_feats**2,axis=1))**0.5;
    norms[norms<=0]             = 1.;
    feats                       = pre_norm_feats / (numpy.outer(norms,numpy.ones(pre_norm_feats.shape[1])));

    return feats;

def prepare_train_set_index(train_uuids):
    uuid_inds       = [];
    timestamps      = [];
    for (uuid_ind,uuid) in enumerate(train_uuids):
        uuid_dir    = os.path.join(g__data_superdir,uuid);
        if not os.path.exists(uuid_dir):
            continue;
        
        for name in os.listdir(uuid_dir):
            if name.isdigit():
                try:
                    timestamp   = int(name);
                    uuid_inds.append(uuid_ind);
                    timestamps.append(timestamp);
                    pass;
                except:
                    continue;
    
                pass; # end if name.isdigit
            pass; # end for name...
        pass; # end for uuid...

    return (uuid_inds,timestamps);