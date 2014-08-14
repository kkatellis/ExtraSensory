# -*- coding: utf-8 -*-
"""
Created on Thu Jun  6 13:50:38 2013

@author: KatEllis
"""
import os
import scipy.io.wavfile as wavfile
from os.path import join, exists, isdir
import subprocess
import mfcc
from numpy import *
#from scipy.stats import *


wins        = 5 #window size in seconds
steps       = 3 #step size in seconds
wins44k      = wins*44100 #44100 Hz data
steps44k     = steps*44100 #44100 Hz data
datatypes   = ['PRE','DUR']
featDir     = '/Users/katellis/feats' #where to put the features
dataset     = '/Users/katellis/rawData' #where to find the raw data

def main():
   
	UIDs 		= [ z for z in os.listdir(dataset) if isdir(join(dataset,z))]
	prefix 	= 'HF_SOUNDWAVE_'
	
	for UID in UIDs:
		print 'feedback ' + UID
		UTime   = UID.rsplit('-')[0] #unique time identifier
		UUID    = UID.rsplit('-')[1] #unique user identifier
		for datatype in datatypes:
			inputfile = join(dataset,UID,prefix+datatype)

			if exists(inputfile):
				print inputfile
				
				tempfile 	= join(dataset,UID,datatype+'.wav')
				
				# use command-line afconvert tool to convert to .wav
				shellcall 	= 'cp ' + inputfile + ' ' + inputfile + '.aiff'
				subprocess.check_call(shellcall, stdin=None, stdout=None, stderr=None, shell=True)	
				shellcall 	= 'afconvert -f WAVE -d LEI16 -c 1 ' + inputfile + '.aiff ' + tempfile
				subprocess.check_call(shellcall, stdin=None, stdout=None, stderr=None, shell=True)
		
				#read the wav file
				Y 		= wavfile.read(tempfile)

				#split up DUR file -it's really DUR + POST
				if datatype == 'DUR':
					if not exists(join(featDir,'POST',UUID,UTime,'mfcc')):
						if size(Y[1],0) > 44100*10:
							#longer than 10 seconds - last 10 are POST
							#compute mfccs
							print ' -splitting DUR and POST'
							print ' -DUR'
							save_mfcc(Y[1][:-44100*10],join(featDir,'DUR',UUID,UTime))
							print ' -POST'
							save_mfcc(Y[1][-44100*10:],join(featDir,'POST',UUID,UTime))
						else:
							#shorter than 10 seconds means POST only
							print ' -POST only', size(Y[1],0)
							save_mfcc(Y[1],join(featDir,'POST',UUID,UTime))
				else:
					#compute mfccs
					if not exists(join(featDir,'PRE',UUID,UTime,'mfcc')):
						save_mfcc(Y[1],join(featDir,'PRE',UUID,UTime))
				
				#remove temp files
				os.remove(inputfile + '.aiff')
				os.remove(tempfile)
				
def save_mfcc(Y,featfile):
	feats = feats_mfcc(Y,wins44k,steps44k)
	if feats.size:
		if not exists(featfile):
			os.makedirs(featfile)
		savetxt(join(featfile,'mfcc'),feats)
	else:
		print '  -not enough data for a feature'

def feats_mfcc(Y,wins,steps):
	fstarts        = range(0,size(Y,0)-wins+1,steps) #index of feature window starts
	f              = 0
	feats          = zeros((len(fstarts),13),dtype=float)  #initialize feature array
	for fs in fstarts:
		ceps, mspec, spec = mfcc.mfcc(Y[fs:fs+wins], nwin=256, nfft=512, fs=44100, nceps=13)
		feats[f,:] = mean(ceps,axis=0)
		f = f + 1
	return feats
	
				
if __name__=="__main__":
   main()			
		
