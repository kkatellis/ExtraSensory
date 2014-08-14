# -*- coding: utf-8 -*-
"""
Created on Fri May 24 15:49:00 2013

@author: KatEllis
"""
# What it does:
#   1. Finds raw data in the raw data folder
#   2. Computes features from each sensor
#   3. Stores features from each sensor in a separate file in the features folder
# file format: .../feats/<PRE/DUR/POST>/UUID/UTimeID/<acc/gyro/gps/mic>
##

import os
from os.path import isdir, join, exists
import numpy as np
import scipy.stats as st
import mfcc
#import statsmodels.tsa.stattools as stattools

dacc        = 44 #dimension of acc features
dgyro       = 44 #dimension of gyro features
dgps        = 4 #dimension of GPS features
dmic        = 10 #dimension of mic features
datatypes   = ['PRE','DUR','POST']
featDir     = '/Users/katellis/feats' #where to put the features
dataset     = '/Users/katellis/rawData' #where to find the raw data
wins        = 5 #window size in seconds    
steps       = 3 #step size in seconds
wins40      = wins*40 #40 Hz data
steps40     = steps*40 #40 Hz data
				
def main():
    
    UIDs =      [ z for z in os.listdir(dataset) if isdir(join(dataset,z))]

    for UID in UIDs:
        #print 'feedback ' + UID
        UTime   = UID.rsplit('-')[0] #unique time identifier
        UUID    = UID.rsplit('-')[1] #unique user identifier
        for datatype in datatypes:
             if exists(join(dataset,UID,datatype)): #check if the PRE/DUR/POST folders exist
                 
                 featfile       = join(featDir,datatype,UUID,UTime)
                 if not exists(featfile): #don't recompute if the feature file already exists
                     print ' -' + featfile
                     acc            = np.loadtxt(join(dataset,UID,datatype,'acc'))
                     gyro           = np.loadtxt(join(dataset,UID,datatype,'gyro'))
                     gps            = np.loadtxt(join(dataset,UID,datatype,'gps'))
                     mic            = np.loadtxt(join(dataset,UID,datatype,'mic'))
                 
                     if np.size(acc,0) < wins40:
                         print '  -not enough data to make a feature'
                         continue
                     if np.size(acc,0)!=np.size(gyro,0):
                         print '  -Warning! Acc and gyro dimensions don''t match'
                     if np.size(acc,0)!=np.size(gps,0):
                         print '  -Warning! Acc and GPS dimensions don''t match'
                     if np.size(acc,0)!=np.size(mic,0):
                         print '  -Warning! Acc and mic dimensions don''t match'

                     os.makedirs(featfile)
                     
                     print '  -extracting accelerometer features...'
                     facc           = feats_acc(acc,wins40,steps40) #accelerometer features
                     np.savetxt(join(featfile,'acc'),facc)
                     
                     print '  -extracting gyroscope features...'
                     fgyro           = feats_gyro(gyro,wins40,steps40) #gyroscope features
                     np.savetxt(join(featfile,'gyro'),fgyro)
                     
                     print '  -extracting GPS features...'
                     fgps           = feats_gps(gps,wins40,steps40) #gps features
                     np.savetxt(join(featfile,'gps'),fgps)
                     
                     print '  -extracting mic features...'
                     fmic           = feats_mic(mic,wins40,steps40) #gps features
                     np.savetxt(join(featfile,'mic'),fmic)

def feats_acc(acc,wins,steps):
    fstarts        = range(0,np.size(acc,0)-wins+1,steps) #index of feature window starts
    f              = 0
    feats          = np.zeros((len(fstarts),dacc))  #initialize feature array
    for fs in fstarts:
        feats[f,:] = one_acc_feat(acc[fs:fs+wins,:])
        f = f + 1
    return feats

def one_acc_feat(win):
    feat            = np.zeros((1,dacc))
    v               = np.sqrt(np.sum(win**2,axis=1))
    feat[0,0]       = np.mean(v)         #average
    feat[0,1]       = np.std(v)          #standard deviation
    if feat[0,1] > 0:
        feat[0,2]   = feat[0,0]/feat[0,1] #coefficient of variation
    else:
        feat[0,2]   = 0
    feat[0,3]       = np.median(v)       #median
    feat[0,4]       = np.amin(v)         #minimum
    feat[0,5]       = np.amax(v)         #maximum
    feat[0,6]       = st.scoreatpercentile(v, 25)    #25th percentile    
    feat[0,7]       = st.scoreatpercentile(v, 75)    #75th percentile
    feat[0,8] 	  = np.correlate(win[:,0],win[:,1]) #xy correlation
    feat[0,9] 	  = np.correlate(win[:,0],win[:,2]) #xz correlation
    feat[0,10] 	  = np.correlate(win[:,1],win[:,2]) #yz correlation
    feat[0,11] 	  = autocorr(v) #lag 40 autocorrelation
    feat[0,12]      = entropy(v) #entropy
    feat[0,13]      = st.moment(v, moment = 3) #third moment
    feat[0,14]      = st.moment(v, moment = 4) #fourth moment
    feat[0,15]      = st.skew(v) #skewness
    feat[0,16]      = st.kurtosis(v) #kurtosis
    feat[0,17]      = np.mean(np.arctan2(win[:,1],win[:,2])) #average roll
    feat[0,18]      = np.mean(np.arctan2(win[:,0],win[:,2])) #average pitch
    feat[0,19]      = np.mean(np.arctan2(win[:,0],win[:,1])) #average yaw
    feat[0,20]      = np.std(np.arctan2(win[:,1],win[:,2])) #std roll
    feat[0,21]      = np.std(np.arctan2(win[:,0],win[:,2])) #std pitch
    feat[0,22]      = np.std(np.arctan2(win[:,0],win[:,1])) #std yaw
    feat[0,23:26]   = princ_dir(win) #prinipal direction of motion via eigen decomposition
    #feat[0,26:32]   = autoreg(v) #5th order auto-regressive model
    feat[0,26:28]   = fft_feats(v) #dominant frequency
    feat[0,28:44]   = fft_coefs(v) #FFT coefficients
    return feat
    
def feats_gyro(gyro,wins,steps):
    fstarts        = range(0,np.size(gyro,0)-wins+1,steps) #index of feature window starts
    f              = 0
    feats          = np.zeros((len(fstarts),dgyro))  #initialize feature array
    for fs in fstarts:
        feats[f,:] = one_gyro_feat(gyro[fs:fs+wins,:])
        f = f + 1
    return feats
        
def one_gyro_feat(win):
    feat            = np.zeros((1,dgyro))
    v               = np.sqrt(np.sum(win**2,axis=1))
    feat[0,0]       = np.mean(v)         #average
    feat[0,1]       = np.std(v)          #standard deviation
    if feat[0,1] > 0:
        feat[0,2]   = feat[0,0]/feat[0,1] #coefficient of variation
    else:
        feat[0,2]   = 0
    feat[0,3]       = np.median(v)       #median
    feat[0,4]       = np.amin(v)         #minimum
    feat[0,5]       = np.amax(v)         #maximum
    feat[0,6]       = st.scoreatpercentile(v, 25)    #25th percentile    
    feat[0,7]       = st.scoreatpercentile(v, 75)    #75th percentile
    feat[0,8] 	  = np.correlate(win[:,0],win[:,1]) #xy correlation
    feat[0,9] 	  = np.correlate(win[:,0],win[:,2]) #xz correlation
    feat[0,10] 	  = np.correlate(win[:,1],win[:,2]) #yz correlation
    feat[0,11] 	  = autocorr(v) #lag 40 autocorrelation
    feat[0,12]      = entropy(v) #entropy
    feat[0,13]      = st.moment(v, moment = 3) #third moment
    feat[0,14]      = st.moment(v, moment = 4) #fourth moment
    feat[0,15]      = st.skew(v) #skewness
    feat[0,16]      = st.kurtosis(v) #kurtosis
    feat[0,17]      = np.mean(np.arctan2(win[:,1],win[:,2])) #average roll
    feat[0,18]      = np.mean(np.arctan2(win[:,0],win[:,2])) #average pitch
    feat[0,19]      = np.mean(np.arctan2(win[:,0],win[:,1])) #average yaw
    feat[0,20]      = np.std(np.arctan2(win[:,1],win[:,2])) #std roll
    feat[0,21]      = np.std(np.arctan2(win[:,0],win[:,2])) #std pitch
    feat[0,22]      = np.std(np.arctan2(win[:,0],win[:,1])) #std yaw
    feat[0,23:26]   = princ_dir(win) #prinipal direction of motion via eigen decomposition
    #feat[0,26:32]   = autoreg(v) #5th order auto-regressive model
    feat[0,26:28]   = fft_feats(v) #dominant frequency
    feat[0,28:44]   = fft_coefs(v) #FFT coefficients
    return feat
				
def feats_gps(gps,wins,steps):
    fstarts        = range(0,np.size(gps,0)-wins+1,steps) #index of feature window starts
    f              = 0
    feats          = np.zeros((len(fstarts),dgps))  #initialize feature array
    for fs in fstarts:
        feats[f,:] = one_gps_feat(gps[fs:fs+wins,:])
        f = f + 1
    return feats
        
def one_gps_feat(win):
    feat            = np.zeros((1,dgps))
    feat[0,0]       = np.mean(win[:,2]) #average speed
    feat[0,1]       = np.std(win[:,2]) #std of speed
    if feat[0,1] > 0:
        feat[0,2]   = feat[0,0]/feat[0,1] #coefficient of variation
    else:
        feat[0,2]   = 0
    feat[0,3]       = np.sqrt(sum((win[-1,:] - win[0,:])**2))
    #print 'mean: ', feat[0,0], ' std: ', feat[0,1], ' cov: ', feat[0,2], ' d: ', feat[0,3]
    return feat 
    
def feats_mic(mic,wins,steps):
    fstarts        = range(0,np.size(mic,0)-wins+1,steps) #index of feature window starts
    f              = 0
    feats          = np.zeros((len(fstarts),dmic))  #initialize feature array
    for fs in fstarts:
        feats[f,:] = one_mic_feat(mic[fs:fs+wins,:])
        f = f + 1
    return feats
        
def one_mic_feat(win):
    feat            = np.zeros((1,dmic))
    feat[0,0]       = np.amax(win[:,0]) #peak db
    feat[0,1]       = np.mean(win[:,1]) #average db
    feat[0,2]       = np.std(win[:,1])          #standard deviation
    if feat[0,2] > 0:
        feat[0,3]   = feat[0,1]/feat[0,2] #coefficient of variation
    else:
        feat[0,3]   = 0
    feat[0,4]       = entropy(win[:,1]) #entropy
    feat[0,5]       = np.median(win[:,1])       #median
    feat[0,6]       = np.amin(win[:,1])         #minimum
    feat[0,7]       = st.scoreatpercentile(win[:,1], 25)    #25th percentile    
    feat[0,8]       = st.scoreatpercentile(win[:,1], 75)    #75th percentile
    feat[0,9]	  = autocorr(win[:,1]) #lag 40 autocorrelation
    return feat 
				
def entropy(v):
    N = np.histogram(v)[0] + 1
    return np.log2(len(v)) - sum(N * np.log2(N))/len(v)
				
def princ_dir(win):
    w,v = np.linalg.eig(np.dot(win.T,win))
    return v[:,np.argsort(w)[-1]]
				
#def autoreg(v):
    #import statsmodels.tsa.ar_model as ar_model
    #return ar_model.AR.fit(ar_model.AR(v), maxlag = 5).params
				
def fft_feats(v):
    import scipy.fftpack as fftpack
    N = 512
    fourier 	= fftpack.fft(v,N)
    freqs   	= fftpack.fftfreq(N,d=1.0/40)
    fsorted 	= np.argsort(abs(fourier[0:N/2]))
    fmax = freqs[fsorted[-2]] #dominant frequency (ignore 0)
    pmax = abs(fourier[fsorted[-2]]) #power @ dominant frequency
    if np.isnan(fmax) or np.isnan(pmax):
        print 'nan'
    return fmax, pmax

def fft_coefs(v):
    import scipy.fftpack as fftpack
    N = 32
    fourier = fftpack.fft(v,N) #fft coefficients
    return abs(fourier[0:N/2])
		
def autocorr(v):
    result = np.correlate(v, v, mode='full')
    return result[result.size/2+40]
				
def feats_mfcc(Y,wins,steps):
	wins44k      = wins*44100 #44100 Hz data
	steps44k     = steps*44100 #44100 Hz data
	fstarts        = range(0,np.size(Y,0)-wins44k+1,steps44k) #index of feature window starts
	f              = 0
	feats          = np.zeros((len(fstarts),13),dtype=float)  #initialize feature array
	for fs in fstarts:
		ceps, mspec, spec = mfcc.mfcc(Y[fs:fs+wins44k], nwin=256, nfft=512, fs=44100, nceps=13)
		feats[f,:] = np.mean(ceps,axis=0)
		f = f + 1
	return feats

if __name__=="__main__":
   print "__name__ == __main__"
   main()