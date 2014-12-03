'''
    activity_analyzer.py

    inputs: zip_in: string - path to a zip file containing data that was just uploaded
		classifier_path: string - path to folder where all the features/classifier stuff is
    output: string - an activity prediction
'''
import os
import subprocess
import json
import zipfile
import numpy as np
import feats
import mlpy
import shutil
import scipy.io.wavfile as wavfile

def classify_zip(zip_in,upload_folder,classifier_path):
    d = zip_in.find('-')
    UTime = zip_in[:d] #unique time identifier
    UUID = zip_in[d+1:].replace(".zip","") #unique user identifier

    # unzip the file
    zf = zipfile.ZipFile(os.path.join(upload_folder,zip_in))
    tmp_dir = os.path.join(classifier_path,zip_in.replace(".zip",""))
    zf.extractall(tmp_dir)

    #compute the features
    feats_acc, feats_magnet, feats_gyro, feats_gps = do_datafile(tmp_dir)
    # save features
    if not os.path.exists(os.path.join(classifier_path,'feats',UUID)):
         os.mkdir(os.path.join(classifier_path,'feats',UUID))
    if not os.path.exists(os.path.join(classifier_path,'feats',UUID,UTime)):
         os.mkdir(os.path.join(classifier_path,'feats',UUID,UTime))
    np.savetxt(os.path.join(classifier_path,'feats',UUID,UTime,'acc'),feats_acc)
    np.savetxt(os.path.join(classifier_path,'feats',UUID,UTime,'magnet'),feats_magnet)
    np.savetxt(os.path.join(classifier_path,'feats',UUID,UTime,'gyro'),feats_gyro)
    np.savetxt(os.path.join(classifier_path,'feats',UUID,UTime,'gps'),feats_gps)
    shutil.rmtree(tmp_dir)
    #concatenate feature vectors
    #	nf = min(feats_acc.shape[0],feats_mfcc.shape[0])
    nf = feats_acc.shape[0]
    #X = np.hstack((feats_acc[0:nf,:],feats_gyro[0:nf,:],feats_gps[0:nf,:],feats_mic[0:nf,:],feats_mfcc[0:nf,:]))
    X = np.hstack((feats_acc[0:nf,:],feats_gyro[0:nf,:],feats_gps[0:nf,:]))
    #predicted_activity = 'something'
    #load the classifier
    svm = mlpy.LibSvm.load_model(os.path.join(classifier_path,'svm'))
    fp = open(os.path.join(classifier_path,'svm_params'),'r')
    params = json.load(fp)
    fp.close()
    mm = np.array(params['m'])
    dd = np.array(params['d'])
    X1 = (X-mm)
    X2 = X1/dd
    X2[np.where(np.isnan(X2))]=0
    np.savetxt(os.path.join(classifier_path,'X'),X2)#	
    predictions = svm.pred(X2)
    print "predictions", predictions
    pr = np.bincount(predictions.astype(int)).argmax()
    predicted_activity = params['activities'][pr - 1] #python indexes from zero
    print "predicted activity: ", predicted_activity;

    return predicted_activity, UTime

def get_measurements_from_json_dict(jdict):
    print "Reading measurements from json structure, assuming dictionary structure";

    # load data into arrays
    try:
        acc = np.array([jdict['processed_user_acc_x'],jdict['processed_user_acc_y'],jdict['processed_user_acc_z']]).T;
        pass;
    except:
        print "-- Missing accelerometer data";
        acc = np.zeros((800,3));
        pass;

    try:
        magnet = np.array([jdict['processed_magnet_x'],jdict['processed_magnet_y'],jdict['processed_magnet_z']]).T;
        pass;
    except:
        print "-- Missing magnetometer data";
        magnet = np.zeros((800,3));
        pass;

    try:
        gyro = np.array([jdict['processed_gyro_x'],jdict['processed_gyro_y'],jdict['processed_gyro_z']]).T;
        pass;
    except:
        print "-- Missing gyroscope data";
        gyro = np.zeros((800,3));
        pass;

    try:
        last_gps_record = np.array([jdict['location_latitude'][-1],jdict['location_longitude'][-1],jdict['location_speed'][-1]]).T;
        gps = np.outer(np.ones(acc.shape[0]),last_gps_record);
        pass;
    except:
        print "-- Missing location data";
        gps = np.zeros((800,3));
        pass;

    return (acc,magnet,gyro,gps);


def get_measurements_from_json_list(jlist):
    print "Reading measurements from json structure, assuming list structure";
    # load data into arrays
    acc = np.zeros((len(jlist),3))
    magnet = np.zeros((len(jlist),3))
    gyro = np.zeros((len(jlist),3))
    gps = np.zeros((len(jlist),3))
    
	#loop through json and write data
    for j in range(len(jlist)):
        acc[j,0] = jlist[j]['acc_x']
        acc[j,1] = jlist[j]['acc_y']
        acc[j,2] = jlist[j]['acc_z']
        magnet[j,0] = jlist[j]['magnet_x']
        magnet[j,1] = jlist[j]['magnet_y']
        magnet[j,2] = jlist[j]['magnet_z']
        gyro[j,0] = jlist[j]['gyro_x']
        gyro[j,1] = jlist[j]['gyro_y']
        gyro[j,2] = jlist[j]['gyro_z']
        gps[j,0] = jlist[j]['lat']
        gps[j,1] = jlist[j]['long']
        gps[j,2] = jlist[j]['speed']
        pass;

    return (acc,magnet,gyro,gps);

def do_datafile(tmp_dir):
	# open the file for reading
	fr = open(os.path.join(tmp_dir,"HF_DUR_DATA.txt"), "r")
        jobj = json.load(fr);
	# close file
	fr.close()

        if (type(jobj) == list):
            (acc,magnet,gyro,gps) = get_measurements_from_json_list(jobj);
            pass;
        else:
            (acc,magnet,gyro,gps) = get_measurements_from_json_dict(jobj);
            pass;

	if acc.shape[0] < feats.wins40:
		raise Exception("Not enough data to make a feature (n = %i)" % acc.shape[0])
	feats_acc = feats.feats_acc(acc,feats.wins40,feats.steps40) #accelerometer features
	feats_magnet = feats.feats_magnet(magnet,feats.wins40,feats.steps40) #magnetometer features
	feats_gyro = feats.feats_gyro(gyro,feats.wins40,feats.steps40) #gryo features
	feats_gps = feats.feats_gps(gps,feats.wins40,feats.steps40) #gps features
#	feats_mic = feats.feats_mic(mic,feats.wins40,feats.steps40) #mic dB features
	return feats_acc, feats_magnet, feats_gyro, feats_gps

def do_soundfile(tmp_dir):
	# load sound file -  use command-line afconvert tool to convert to .wav
	soundfile = os.path.join(tmp_dir,"HF_SOUNDWAVE")
	shellcall 	= 'mv ' + soundfile + ' ' + soundfile + '.aiff'
	subprocess.check_call(shellcall, stdin=None, stdout=None, stderr=None, shell=True)	
	shellcall 	= 'afconvert -f WAVE -d LEI16 -c 1 ' + soundfile + '.aiff ' + soundfile + '.wav'
	subprocess.check_call(shellcall, stdin=None, stdout=None, stderr=None, shell=True)
			
	#read the wav file
	Y 		= wavfile.read(soundfile + '.wav')
	feats_mfcc = feats.feats_mfcc(Y[1],feats.wins,feats.steps)
	#remove temp files
	os.remove(soundfile + '.aiff')
	os.remove(soundfile + '.wav')
	return feats_mfcc
	
