#!/usr/bin/env python
'''
Calculate features from the raw data

Written by Yonatan Vaizman. Nov 2013.
Adopted for ExtraSensory mobile sensing processing, Nov 2014.
'''

import os;
import os.path;
import pickle;
import numpy;
import numpy.fft;
import scipy.signal;
import scipy.spatial.distance;
import shutil;
import datetime;
import pdb;
import pylab;pylab.ion();



def get_3d_series_features(X,sr):
    # First rotate the observation vectors around the origin,
    # according to their principal components:
    unrotated       = numpy.copy(X);
    (X,pca_mat,lam) = rotate_by_PCA(X);
    pc1             = pca_mat[:,0].tolist();
    norm_lam        = lam / numpy.sum(lam);

    # Magnitude:
    mag         = numpy.sum(X**2,axis=1)**0.5;
    
    # Detect dominant frequencies:
    dft_dom_freq_feat = get_dominant_freq_by_dft(X,sr);

    # Statistics:
    pc1_stats   = get_1d_statistics(X[:,0]);
    mag_stats   = get_1d_statistics(mag);
    cross_stats = get_cross_dim_statistics(X);
    cross_raw   = get_cross_dim_statistics(unrotated);

    # Organize features:
    feats = [];
    feats.extend(pc1);
    feats.extend([norm_lam[0],norm_lam[1]]);
    feats.extend(dft_dom_freq_feat);
    feats.extend(pc1_stats);
    feats.extend(mag_stats);
    feats.extend(cross_stats);
    feats.extend(cross_raw);

    return feats;

'''
Input:
X: (T x d) d dimensional time series.

Output:
'''
def get_cross_dim_statistics(X):
    
    roll    = numpy.arctan2(X[:,1],X[:,2]);
    pitch   = numpy.arctan2(X[:,0],X[:,2]);
    yaw     = numpy.arctan2(X[:,0],X[:,1]);

    stats   = [\
        numpy.mean(roll),\
        numpy.mean(pitch),\
        numpy.mean(yaw),\
        numpy.std(roll),\
        numpy.std(pitch),\
        numpy.std(yaw)\
        ];

    return stats;


'''
Input:
x: (T x 1) 1 dimensional time series.

Output:
'''
def get_1d_statistics(x):
    mom3    = scipy.stats.moment(x,moment=3);
    absx    = abs(x);
    if sum(absx)>0:
        ent = scipy.stats.entropy(absx);
        pass;
    else:
        ent = 0.;
        pass;
    stats   = [\
        numpy.mean(x),\
        numpy.std(x),\
        numpy.sign(mom3)*(abs(mom3)**(1./3.)),\
        scipy.stats.moment(x,moment=4)**(1./4.),\
        ent,\
        numpy.median(x),\
        ];

    return stats;

'''
Input:
X: (T x d) matrix. T observations of d dimensions.
sr: scalar. Sampling rate (Hz).

Output:
dom_freqs:   d-array. Dominant frequency (same units as sr) in each dimension.
dom_periods: d-array. Inverse of the frequencies.
dom_power:   d-array. Normalized power of the dominant frequencies.
'''
def get_dominant_freq_by_autoregression(X,sr):
    (T,d) = X.shape;
    return None;

'''
Input:
X: (T x d) matrix. T observations of d dimensions.
sr: scalar. Sampling rate (Hz).

Output:
dom_freqs:   d-array. Dominant frequency (same units as sr) in each dimension.
dom_periods: d-array. Inverse of the frequencies.
dom_power:   d-array. Normalized power of the dominant frequencies.
'''
def get_dominant_freq_by_dft(X,sr):
    (T,d) = X.shape;
    ham   = numpy.reshape(numpy.hamming(T),(T,1));
    # Window the time series:
    X     = ham*X;
    # Calculate the DFT and the power spectrum for each dimension:
    Y     = numpy.fft.rfft(X,axis=0);
    PS    = abs(Y)**2;
    power = numpy.reshape(numpy.sum(PS,axis=0),(1,d));
    power[power<=0.0]   = 1.;
    nPS   = PS / power;
    freqs = numpy.fft.fftfreq(T,1./sr);

    # Find the strongest peak in each dimension:
    dom_freqs   = numpy.zeros(d).tolist();
    dom_periods = numpy.zeros(d).tolist();
    dom_power   = numpy.zeros(d).tolist();
    spec_ent    = numpy.zeros(d).tolist();
    for jj in range(d):
        extrema = scipy.signal.argrelmax(nPS[:,jj])[0];
        if len(extrema) <= 0:
            continue;
        extvals = nPS[extrema,jj];
        ind     = numpy.argmax(extvals); # index among the local peaks
        ind     = extrema[ind]; # index among all the DFT components
        
        dom_freqs[jj]   = freqs[ind];
        dom_periods[jj] = 1/dom_freqs[jj];
        dom_power[jj]   = nPS[ind,jj];
        spec_ent[jj]    = scipy.stats.entropy(nPS[:,jj]);
        pass;

    dom_freq_feat = [];
    dom_freq_feat.extend(dom_freqs);
    dom_freq_feat.extend(dom_periods);
    dom_freq_feat.extend(dom_power);
    dom_freq_feat.extend(spec_ent);

    return dom_freq_feat;

'''
Input:
X: (T x d) matrix. T observations of d dimensions.

Output:
Y: (T x d) matrix. The rotated observation vectors.
pca_mat: (d x d) matrix. The columns are the eigenvectors.
lam: d-array. The eigenvalues (from high to low).
'''
def rotate_by_PCA(X):
    (T,d)   = X.shape;

    # First, in case X is constant, return degenerate pca:
    epsilon     = 1e-10;
    if max(numpy.std(X,axis=0)) <= epsilon:
        Y   = X;
        pca_mat = numpy.eye(d);
        lam     = numpy.ones(d);
        return (Y,pca_mat,lam);
    
    # Assume the center is the origin
    C       = numpy.dot(X.T,X) / float(T);
    (w,v)   = numpy.linalg.eig(C);

    sorted_ind_lam_pairs = sorted(enumerate(w),key=lambda pair:pair[1],reverse=True);
    order   = [pair[0] for pair in sorted_ind_lam_pairs];
    lam     = w[order];
    pca_mat = v[:,order];
    Y       = numpy.dot(X,pca_mat);

    return (Y,pca_mat,lam);

LOC_TIME    = 0;
LOC_LAT     = 1;
LOC_LONG    = 2;
LOC_ALT     = 3;
LOC_SPEED   = 4;
LOC_HOR     = 5;
LOC_VER     = 6;

'''
Input:
X: (T x 7) matrix. Each row is a record indicating significant change from
    the previous location state and includes:
    timestamp, latitude, longitude, altitude, estimated speed,
    horizontal accuracy and vertical accuracy
start_timestamp: timestamp of the start of this instance.

Output:
location_feat: 
'''
def get_location_features(X,start_timestamp):
    # Check if there is actual location data:
    if len(X.shape) <= 0:
        return None;
    
    # First filter out too-old location-updates (from the cache):
    valid_inds      = numpy.where(X[:,LOC_TIME] >= (start_timestamp-0.5))[0];
    X               = X[valid_inds,:];

    # Horizontal location:
    valid_hor_inds  = numpy.where(X[:,LOC_HOR]>0.)[0];
    if len(valid_hor_inds) <= 0:
        best_hor_acc    = numpy.nan;
        std_lat         = numpy.nan;
        std_long        = numpy.nan;
        diameter        = numpy.nan;
        X_hor           = X[valid_hor_inds,:];
        pass;
    else:
        best_hor_acc    = numpy.min(X[valid_hor_inds,LOC_HOR]);
        hor_threshold   = 3.*best_hor_acc;
        hor_good_inds   = numpy.where((X[:,LOC_HOR]>0.) & (X[:,LOC_HOR]<hor_threshold))[0];
        X_hor           = X[hor_good_inds,:];

        (avr_lat,std_lat)   = get_statistic_with_relative_durations(\
            X_hor[:,LOC_TIME],X_hor[:,LOC_LAT]);
        (avr_long,std_long) = get_statistic_with_relative_durations(\
            X_hor[:,LOC_TIME],X_hor[:,LOC_LONG]);

        diameter        = find_largest_geographic_distance(\
            X_hor[:,LOC_LAT],X_hor[:,LOC_LONG]);
        pass;

    # Speed:
    sp_valid_inds   = numpy.where(X_hor[:,LOC_SPEED]>=0.)[0];
    if len(sp_valid_inds) <= 0:
        min_speed       = numpy.nan;
        max_speed       = numpy.nan;
        avr_speed       = numpy.nan;
        std_speed       = numpy.nan;
        pass;
    else:
        speed_vals      = X_hor[sp_valid_inds,LOC_SPEED];
        speed_times     = X_hor[sp_valid_inds,LOC_TIME];
        min_speed       = numpy.min(speed_vals);
        max_speed       = max(speed_vals);
        (avr_speed,std_speed)   = get_statistic_with_relative_durations(\
            speed_times,speed_vals);
        pass;

    # Altitude:
    valid_ver_inds  = numpy.where(X[:,LOC_VER]>0.)[0];
    if len(valid_ver_inds) <= 0:
        best_ver_acc    = numpy.nan;
        std_alt         = numpy.nan;
        alt_range       = numpy.nan;
        pass;
    else:
        best_ver_acc    = numpy.min(X[valid_ver_inds,LOC_VER]);
        ver_threshold   = 3.*best_ver_acc;
        ver_good_inds   = numpy.where(\
            (X[:,LOC_VER]>0.) & (X[:,LOC_VER]<ver_threshold))[0];
        X_ver           = X[ver_good_inds,:];

        (avr_alt,std_alt)   = get_statistic_with_relative_durations(\
            X_ver[:,LOC_TIME],X_ver[:,LOC_ALT]);
        min_altitude    = min(X_ver[:,LOC_ALT]);
        max_altitude    = max(X_ver[:,LOC_ALT]);
        alt_range       = max_altitude - min_altitude;
        pass;

    location_feat   = [];
    location_feat.append(best_hor_acc);
    location_feat.append(best_ver_acc);
    location_feat.append(std_lat);
    location_feat.append(std_long);
    location_feat.append(std_alt);
    location_feat.append(alt_range);
    location_feat.append(avr_speed);
    location_feat.append(std_speed);
    location_feat.append(min_speed);
    location_feat.append(max_speed);
    location_feat.append(diameter);
    
    return location_feat;

def get_statistic_with_relative_durations(timestamps,values):
    if len(values) == 1:
        return (values[0],0.);
    
    used_values     = values[:-1];
    durations       = timestamps[1:]-timestamps[:-1];
    total_time      = sum(durations);

    sum_vals        = sum(used_values*durations);
    avr_val         = sum_vals / total_time;

    centered        = used_values - avr_val;
    sum_squares     = sum((centered**2)*durations);
    std_val         = (sum_squares / total_time)**0.5;

    return (avr_val,std_val);

def find_largest_geographic_distance(latitudes,longitudes):
    # Convert degrees to radians:
    deg2rad         = numpy.pi / 180.;
    r_latitudes     = deg2rad * latitudes;
    r_longitudes    = deg2rad * longitudes;

    max_dist        = 0.;
    for ii in range(len(latitudes)):
        for jj in range(ii+1,len(latitudes)):
            d       = distance_between_geographic_points(\
                r_latitudes[ii],r_longitudes[ii],\
                r_latitudes[jj],r_longitudes[jj]);
            if d > max_dist:
                max_dist    = d;
                pass;
            
            pass;
        pass;

    return max_dist;

EARTH_RADIUS        = 6371000;

def distance_between_geographic_points(r_lat1,r_long1,r_lat2,r_long2):
    lat_diff        = r_lat1 - r_lat2;
    long_diff       = r_long1 - r_long2;

    a               = numpy.sin(lat_diff/2.)**2 + \
                      numpy.cos(r_lat1)*numpy.cos(r_lat2)*(numpy.sin(long_diff/2.)**2);
    arc_angle       = 2*numpy.arctan2((a**0.5)*((1-a)**0.5),1.);
    arc_length      = EARTH_RADIUS * arc_angle;

    return arc_length;

def main():
    uuid_dir        = 'uuids/EAF71BC5-5744-47E0-A883-CBE0F77BF6B9';
    instance        = '1416418500'; #'1415333142';#limor-driving#'1415320845';#sitting
    instance_dir    = os.path.join(uuid_dir,instance);
    timestamp       = float(instance);
    
    loc = numpy.genfromtxt(os.path.join(instance_dir,'m_location'));
    location_feat   = get_location_features(loc,timestamp);
    pdb.set_trace();

if __name__ == "__main__":
    main();
