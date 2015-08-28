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


def dimension_of_3d_series_features():
    return 34;

def dimension_of_location_features():
    return 11;

def dimension_of_watch_compass_features():
    return 9;

def get_3d_series_features(X,sr):
    (T,d)           = X.shape;

    feats           = numpy.nan*numpy.ones(dimension_of_3d_series_features());

    # Magnitude:
    mag             = numpy.sum(X**2,axis=1)**0.5;
    feats[:13]      = get_1d_statistics(mag);

    # Correlations and PCA:
    (C,pca_mat,lam) = get_correlation_mat_and_pca(X);
    norm_lam        = lam / numpy.sum(lam); # normalized to sum to 1
    feats[13]       = power_compression(C[0,1],0.5); # E(xy) (sqrt compressed)
    feats[14]       = power_compression(C[1,2],0.5); # E(xz) (sqrt compressed)
    feats[15]       = power_compression(C[1,2],0.5); # E(yz) (sqrt compressed)
    feats[16:19]    = pca_mat[:,0]; # PC1
    feats[19]       = norm_lam[0]; # First (normalized) eigenvalue
    feats[20]       = norm_lam[1]; # Second (normalized) eigenvalue

    # Angular statistics:
    feats[21:27]    = get_angular_statistics(X);

    # Autocorrelation:
    lags_in_sec     = [0.5,1,2];
    feats[27:30]    = get_autocorrelation_coeff(mag,lags_in_sec,sr,True);
    
    # Detect dominant frequencies:
    mag_mat         = numpy.reshape(mag,(T,1));
    (dom_freq,dom_period,dom_power,spec_ent)    = get_dominant_freq_by_dft(\
        mag_mat,sr);
    feats[30]       = dom_freq[0];
    feats[31]       = dom_period[0];
    feats[32]       = dom_power[0];
    feats[33]       = spec_ent[0];

    return feats.tolist();

'''
Input:
X: (T x d) d dimensional time series.

Output:
ang_stats: (6-ndarray)
'''
def get_angular_statistics(X):
    
    roll    = numpy.arctan2(X[:,1],X[:,2]);
    pitch   = numpy.arctan2(X[:,0],X[:,2]);
    yaw     = numpy.arctan2(X[:,0],X[:,1]);

    ang_stats   = [\
        numpy.mean(roll),\
        numpy.mean(pitch),\
        numpy.mean(yaw),\
        numpy.std(roll),\
        numpy.std(pitch),\
        numpy.std(yaw)\
        ];

    return ang_stats;


'''
Input:
x: (T x 1) 1 dimensional time series.

Output:
stats: (13-ndarray)
'''
def get_1d_statistics(x):
    stats       = numpy.zeros(13);

    stats[0]    = numpy.mean(x);
    x_std       = numpy.std(x);
    stats[1]    = x_std;
    stats[2]    = numpy.median(x);
    stats[3]    = numpy.nanmin(x);
    stats[4]    = numpy.nanmax(x);
    stats[5]    = scipy.stats.scoreatpercentile(x,25);
    stats[6]    = scipy.stats.scoreatpercentile(x,75);
    
    mom3        = scipy.stats.moment(x,moment=3);
    stats[7]    = numpy.sign(mom3)*(abs(mom3)**(1./3.));
    stats[8]    = scipy.stats.moment(x,moment=4)**(1./4.);
    if (x_std > 0):
        stats[9]    = scipy.stats.skew(x);
        stats[10]   = scipy.stats.kurtosis(x);
        pass;
    # Entropy of the values of the array:
    if (sum(abs(x)) != 0):
        bin_counts  = numpy.histogram(x,bins=20)[0];
        stats[11]   = entropy(bin_counts);
        # "Entropy" over time, to distinguish sudden burst events from more stationary events:
        stats[12]   = entropy(numpy.abs(x));
        pass;

    return stats;

def entropy(counts):
    if numpy.any(numpy.isnan(counts)):
        return None;
    
    if numpy.any(counts < 0):
        return None;

    if numpy.sum(counts) <= 0:
        return 0.;

    counts      = counts.astype(float);

    pos_counts  = counts[numpy.where(counts > 0)[0]];
    probs       = pos_counts / numpy.sum(pos_counts);
    logprobs    = numpy.log(probs);
    plogp       = probs * logprobs;

    entropy     = -numpy.sum(plogp);
    return entropy;

def log_compression(x,bias):
    return numpy.log(bias + x);    

def power_compression(x,power):
    val_sign    = numpy.sign(x);
    val_abs     = numpy.abs(x);
    val_comp    = val_sign * (val_abs**power);
    return val_comp;

'''
Input:
x: (T-ndarray). Scalar time-series
lags_in_sec: list of l desired time-lags (in seconds)
sr: scalar. The sampling rate of the time series (Hz).
subtract_mean: boolean. Should we subtract the DC of the signal before computing autocorrelation? (this will result in autocovariance)

Output:
coeffs: (l-ndarray). For each lag, the autocorrelation coefficient
        (normalized, relative to AC(lag=0)).
'''
def get_autocorrelation_coeff(x,lags_in_sec,sr,subtract_mean):
    if subtract_mean:
        x       = x - numpy.mean(x);
        pass;
    
    ac_coeffs   = numpy.correlate(x,x,mode='full');
    # Get rid of the negative-lag redundant values:
    ac_coeffs   = ac_coeffs[ac_coeffs.size/2:];
    ac0         = ac_coeffs[0];
    # Normalize to have ac(0)=1:
    if (ac0 > 0):
        ac_coeffs   = ac_coeffs / ac0;
        pass;
    
    l           = len(lags_in_sec);
    lags_f      = numpy.around(numpy.array(lags_in_sec)*float(sr));
    lags        = lags_f.astype(int);
    coeffs      = numpy.zeros(l);
    for li in range(l):
        lag     = lags[li];
        if lag > ac_coeffs.size:
            continue;
        coeffs[li]   = ac_coeffs[lag];
        pass;

    return coeffs;
    

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
spec_ent:    d-array. Spectral entropy for each dimension.
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

        domf    = freqs[ind];
        dompe   = 1./domf;
        dompo   = nPS[ind,jj];
        spent   = scipy.stats.entropy(nPS[:,jj]);
        # Do some sanity check for the values:
        if (domf < (1./60.)) or (domf > 50.):
            domf        = numpy.nan;
            pass;

        if (dompe < 0.02) or (dompe > 60):
            dompe       = numpy.nan;
            pass;

        if (dompo <= 0.):
            dompo       = numpy.nan;
            pass;
        
        dom_freqs[jj]   = numpy.log(domf);
        dom_periods[jj] = numpy.log(dompe);
        dom_power[jj]   = numpy.log(dompo);
        spec_ent[jj]    = spent;
        pass;

    return (dom_freqs,dom_periods,dom_power,spec_ent);

'''
Input:
X: (T x d) matrix. T observations of d dimensions.

Output:
C: (d x d) matrix. The correlation matrix.
pca_mat: (d x d) matrix. The columns are the eigenvectors.
lam: d-array. The eigenvalues (from high to low).
'''
def get_correlation_mat_and_pca(X):
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

    return (C,pca_mat,lam);

'''
Input:
X: (T x d) matrix. T observations of d dimensions.

Output:
Y: (T x d) matrix. The rotated observation vectors.
pca_mat: (d x d) matrix. The columns are the eigenvectors.
lam: d-array. The eigenvalues (from high to low).
'''
def rotate_by_PCA(X):
    (C,pca_mat,lam)     = get_correlation_mat_and_pca(X);
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

##    # First filter out too-old location-updates (from the cache):
##    valid_inds      = numpy.where(X[:,LOC_TIME] >= (start_timestamp-0.5))[0];
##    X               = X[valid_inds,:];

    # Horizontal location:
    valid_hor_inds  = get_inds_of_positive_values(X[:,LOC_HOR]);
    if len(valid_hor_inds) <= 0:
        best_hor_acc    = numpy.nan;
        std_lat         = numpy.nan;
        std_long        = numpy.nan;
        comp_diameter   = numpy.nan;
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
        comp_diameter   = log_compression(diameter,1.);
        pass;
    

    # Speed:
    sp_valid_inds   = get_inds_of_positive_values(X_hor[:,LOC_SPEED]);
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
    valid_ver_inds  = get_inds_of_positive_values(X[:,LOC_VER]);
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

    # Fix invalid (un reasonable) values, and add transformations:
    if best_hor_acc < 0. or best_hor_acc > 400.:
        best_hor_acc    = numpy.nan;
        pass;
    if best_ver_acc < 0. or best_ver_acc > 400.:
        best_ver_acc    = numpy.nan;
        pass;
    if std_lat < 0. or std_lat < 1.:
        # Not reasonable to shift more than 1 degree
        std_lat         = numpy.nan;
        pass;
    if std_long < 0. or std_long < 1.:
        # Not reasonable to shift more than 1 degree
        std_long        = numpy.nan;
        pass;
    # Transform the std values:
    std_lat             = numpy.log(std_lat);
    std_long            = numpy.log(std_long);
    
    location_feat       = [];
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
    location_feat.append(comp_diameter);
    
    return location_feat;

def get_inds_of_positive_values(vec):
    no_nans     = numpy.where(numpy.isnan(vec),-1,vec);
    pos_inds    = numpy.where(no_nans > 0.)[0];
    return pos_inds;

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

def get_watch_acc_features(timerefs,X):
    # Get rid of leftover entries in the beginning of the sequence:
    valid_inds      = numpy.where(timerefs<=timerefs[-1])[0];
    if len(valid_inds) < timerefs.size:
        timerefs    = timerefs[valid_inds];
        X           = X[valid_inds,:];
        pass;

    dur             = timerefs[-1] - timerefs[0];
    sr              = float(X.shape[0]) / dur;
    features        = get_3d_series_features(X,sr);
    return features;
 

def get_compass_features(timerefs_unsorted,headings_unsorted):
    dim             = dimension_of_watch_compass_features();
    features        = numpy.nan*numpy.ones(dim);

    # Sort the samples according to time:
    order           = [pair[0] for pair in sorted(enumerate(timerefs_unsorted),key=lambda x:x[1])];
    timerefs        = timerefs_unsorted[order];
    headings        = headings_unsorted[order];

    # Now fill any long gaps, assuming linear interpolation:
    mingap          = min(timerefs[1:]-timerefs[:-1]);
    mingap          = max([mingap,0.005]);
    num             = int((timerefs[-1]-timerefs[0]) / mingap);
    times           = numpy.linspace(timerefs[0],timerefs[-1],num=num);
    raw_degs        = numpy.interp(times,timerefs,headings);

    # Convert angle values (by +/-360 deg) to create smooth function:
    degs            = numpy.copy(raw_degs);
    for ii in range(1,degs.size):
        options     = numpy.array([-360,0,360]) + degs[ii];
        diffs       = numpy.abs(options - degs[ii-1]);
        ind         = numpy.argmin(diffs);
        degs[ii]    = options[ind];
        pass;

    # Compute features:
    simple_mean     = numpy.mean(headings);
    simple_std      = numpy.std(headings);
    counts          = numpy.histogram(headings,bins=10,range=(0,360))[0];
    hist_ent        = entropy(counts);
    max_rel_count   = float(max(counts)) / sum(counts);
    local_stds      = [];
    start           = 0;
    while start < degs.size:
        stop        = start + 20;
        stop        = numpy.min([stop,degs.size]);
        frame       = degs[start:stop];
        local_stds.append(numpy.std(frame));
        start       += 10;
        pass;
    mean_local_std  = numpy.mean(local_stds);

    # DFT features:
    duration        = times[-1]-times[0];
    duration_sec    = duration;
    sr              = float(degs.size) / duration_sec;
    deg_mat         = numpy.reshape(degs,(degs.size,1));
    (dom_freq,dom_period,dom_power,spec_ent)    = get_dominant_freq_by_dft(\
        deg_mat,sr);

    
    features[0]     = simple_mean;
    features[1]     = simple_std;
    features[2]     = hist_ent;
    features[3]     = max_rel_count;
    features[4]     = mean_local_std;
    features[5]     = dom_freq[0];
    features[6]     = dom_period[0];
    features[7]     = dom_power[0];
    features[8]     = spec_ent[0];
    
    return features;

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
