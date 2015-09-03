'''
feature_codebooks.py

--------------------------------------------------------------------------
Written by Yonatan Vaizman. August 2015.
'''

import random;
import numpy;
import sklearn.cluster;
import pdb;



'''
Initialize a k-means codebook using an initialization batch of examples.

Input:
init_batch_feats: (N x d). N examples of d-dimensional feature vectors.
k: positive integer. The codebook size (number of codewords).
normalize: boolean. Should we normalize each codeword to have unit L2-norm?

Output:
codebook: (k x d). k codewords. The initialized codebook.
'''
def initialize_k_means_codebook(init_batch_feats,k,normalize=True):
    init_kmeans                 = sklearn.cluster.KMeans(n_clusters=k);
    init_kmeans.fit(init_batch_feats);
    codebook                    = init_kmeans.cluster_centers_;
    if normalize:
        codebook                = normalize_feature_vectors(codebook);
        pass;

    return codebook;

'''
Perform a single iteration of k-means, including quantizing each example
in the minibatch to a single codeword, and then updating the codewords
according to their assigned examples.

Input:
codebook: (k x d). k codewords. The current codebook.
minibatch_feats (N x d). N feature vectors that were quantized to the codebook.
normalize: boolean. Should we normalize each codeword to have unit L2-norm?

Output:
codebook: (k x d). The updated codebook at the end of the k-means interation.
'''
def k_means_iteration(codebook,minibatch_feats,normalize=True):
    # Quantize each feature vector to the closest codeword:
    code_mat                    = vector_quantization(minibatch_feats,codebook,1);
    # Update the codebook using the codes:
    codebook                    = update_k_means_codebook(codebook,minibatch_feats,code_mat,normalize);

    return codebook;
    

'''
Update the current codebook, based on VQ-1 coding of a minibatch.
For each codeword, gather the features that were quantized to it,
calculate their mean, normalize to unit L2-norm (if required), and that is the new codeword.
If a codeword had no vectors quantized to it, leave it as it is.

Input:
codebook: (k x d). k codewords. The current codebook.
minibatch_feats: (N x d). N feature vectors that were quantized to the codebook.
code_mat: (N x k) binary. For each example out of N vectors the identity of codeword(s) it was quantized to.
normalize: boolean. Should we normalize each codeword to have unit L2-norm?

Output:
codebook: (k x d). 
'''
def update_k_means_codebook(codebook,minibatch_feats,code_mat,normalize):
    for ci in range(codebook.shape[0]):
        inds                = numpy.where(code_mat[:,ci])[0];
        if (len(inds) > 0):
            cluster         = minibatch_feats[inds,:];
            codebook[ci,:]  = numpy.mean(cluster,axis=0);
            pass; # end if...
        pass; # end for ci...

    if normalize:
        # Normalize all codewords:
        codebook                = normalize_feature_vectors(codebook);
        pass;
    
    return codebook;

'''
Quantize each feature vector in features to the tau closest codewords from the codebook.

Input:
features: (N x d). N feature vectors of dimension d. Assuming each feature vector has unit L2-norm.
codebook: (k x d). k codewords (centroids) of dimension d. Assuming each codeword has unit L2-norm.
tau: scalar. How many codewords to quantize to.

Output:
code_mat: (N x k). binary matrix. Each feature vector's code vector, with 1 in the positions of the centroids it was quantized to.
'''
def vector_quantization(features,codebook,tau):
    dot_prods                   = numpy.dot(features,codebook.T);
    N                           = features.shape[0];
    k                           = codebook.shape[0];

    code_mat                    = numpy.zeros((N,k));
    for ii in range(N):
        dots                    = dot_prods[ii,:];
        closest_to_farthest     = [pair[0] for pair in sorted(enumerate(dots),key=lambda x: x[1],reverse=True)];
        quant                   = closest_to_farthest[:tau];
        code_mat[ii,quant]      = 1;
        pass;

    return code_mat;

'''
Normalize each feature vector to have unit L2 norm.

Input:
pre_norm_feats: (N x d). N examples of d-dimensional feature vectors.

Output:
feats: (N x d). N examples of the normalized feature vectors.
'''
def normalize_feature_vectors(pre_norm_feats):
    norms                       = (numpy.sum(pre_norm_feats**2,axis=1))**0.5;
    norms[norms<=0]             = 1.;
    feats                       = pre_norm_feats / (numpy.outer(norms,numpy.ones(pre_norm_feats.shape[1])));

    return feats;
