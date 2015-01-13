'''
    analyze.py

    API functions to handle data analyzing and feedback from the device
'''
import os
import os.path
import datetime
import json
import pymongo
import pytz
import shlex, subprocess
import activity_analyzer
import sys

from random import randint

from flask import abort, current_app, Blueprint, request
from werkzeug import secure_filename

from server.db import song_to_dict

NUM_SONGS       = 6
NUM_RAND_SONGS  = 2

analyzer_api = Blueprint( 'analyzer_api', __name__ )

ALLOWED_EXTENSIONS = set( ['zip'] )

GPS_FMT  = '"%f" "%f" "%f" "%s"'
ACC_FMT  = '"%f" "%f" "%f"'
GYRO_FMT = '"%f" "%f" "%f"'
MIC_FMT  = '"%f" "%f"'

@analyzer_api.route( '/analyze' )
def analyze():
    connection = pymongo.Connection()
    rmwdb = connection[ 'rmw' ]
    songs = rmwdb.songs

    try:
        prev_gps = GPS_FMT % ( float( request.args.get( 'prev_lat' ) ), 
                     float( request.args.get( 'prev_long' ) ),
                     float( request.args.get( 'prev_speed' ) ),
                     request.args.get( 'prev_timestamp' ) )

        curr_gps = GPS_FMT % ( float( request.args.get( 'lat' ) ), 
                     float( request.args.get( 'long' ) ),
                     float( request.args.get( 'speed' ) ),
                     request.args.get( 'timestamp' ) ) 

        acc_data = ACC_FMT % ( float( request.args.get( 'acc_x' ) ),
                            float( request.args.get( 'acc_y' ) ),
                            float( request.args.get( 'acc_z' ) ) )
                            
        gyro_dat = GYRO_FMT % ( float( request.args.get( 'gyro_x' ) ),
                            float( request.args.get( 'gyro_y' ) ),
                            float( request.args.get( 'gyro_z' ) ) )

        mic_data = MIC_FMT % ( float( request.args.get( 'mic_avg_db' )),
                                float( request.args.get( 'mic_peak_db' ) ) )
    except Exception, error:
        print error
        abort( 400 )

    # Save data if we have a UDID & tags parameters
    if 'udid' in request.args and 'tags' in request.args:
        activity_data = rmwdb.activitydata

        data_obj = dict( request.args )

        # Remove GPS timestamp info before sending to database
        del( data_obj[ 'timestamp' ] )
        del( data_obj[ 'prev_timestamp' ] )

        for key in data_obj.keys():
            if 'tags' not in key and 'udid' not in key:
                data_obj[ key ] = float( data_obj[ key ][0] )
            else:
                data_obj[ key ] = data_obj[ key ][0]

        # Split up the calibrate tags
        data_obj[ 'tags' ] = [ x.strip() for x in request.args.get( 'tags' ).split( ',' ) ]
        data_obj[ 'timestamp' ] = datetime.datetime.utcnow()

        activity_data.insert( data_obj )

    # Join up the arguments and call the Analzyer
    arguments = ' '.join( [ prev_gps, curr_gps, acc_data, gyro_dat, mic_data ] )

    final_call = str( current_app.config[ 'ANALYZER_PATH' ] % ( arguments ) )
    process = subprocess.Popen( shlex.split( final_call ), stdout=subprocess.PIPE ).stdout

    # Read the activites from the analyzer output
    activities = []
    for line in process.readlines():
        activities.append( line.strip() )

    # call song recommendation engine
    playlist = []

    # Get the number of songs with this activity
    num_songs = 0
    i = 0
    while num_songs == 0 and i < len( activities ):
        num_songs = songs.find( {'activities': activities[0] } ).count()

        if num_songs == 0:
            activities = activities[1:]

    for idx in xrange( NUM_SONGS ):
        try:
            song = songs.find( {'activities': activities[0] } )\
                        .skip( randint( 0, num_songs - 1 ) )\
                        .limit ( 1)
        except IndexError, error:
            print error
            continue

        song = [ x for x in song ]
        if len( song ) > 0:
            playlist.append( song_to_dict( song[0] ) )

    # Get the number of songs without any tags
    # Empty string indicates a song with no activity tags
    num_songs = songs.find( {'activities': '' } ).count()

    for idx in xrange( NUM_RAND_SONGS ):
        try:
            song = songs.find( {'activities': '' } )\
                        .skip( randint( 0, num_songs - 1 ) )\
                        .limit( 1 )
        except IndexError, error:
            print error
            continue

        playlist.append( song_to_dict( song[0] ) )

    results = {}
    results[ 'activities' ] = activities
    results[ 'playlist' ] = playlist
    return json.dumps( results )

def allowed_file( filename ):
    return '.' in filename and filename.rsplit( '.', 1 )[1] in ALLOWED_EXTENSIONS

def get_and_create_upload_instance_dir(UUID,UTime):
    # Create a directory for this instance:
    uuid_dir = os.path.join(current_app.config['UPLOAD_FOLDER'],UUID);
    if not os.path.exists(uuid_dir):
        os.mkdir(uuid_dir);
        pass;
    
    instance_dir = os.path.join(uuid_dir,UTime);
    if not os.path.exists(instance_dir):
        os.mkdir(instance_dir);
        pass;

    return instance_dir;


@analyzer_api.route( '/feedback_upload', methods=[ 'POST' ] )
def feedback_upload():
    print 'feedback_upload()'
    '''
        Handles saving feedback high frequency (HF) data and sound wave data
        collection. The app zips up the HF data and sound wave and uploads
        it to this URL.

        Parameters
        ----------
        file - ZIP file data

        Results
        -------
        JSON success if the file was successfully uploaded
        JSON failure otherwise
    '''
    try:
    	uploaded_file = request.files[ 'file' ]
        filename = secure_filename( uploaded_file.filename )

        d = filename.find('-')
        UTime = filename[:d] #unique time identifier
        UUID = filename[d+1:].replace(".zip","") #unique user identifier

        instance_dir = get_and_create_upload_instance_dir(UUID,UTime);
        fullfilename = os.path.join(instance_dir,filename);
        uploaded_file.save( fullfilename )
        print 'saved ', fullfilename
	
	#now predict the activity

        predicted_activity, UTime = activity_analyzer.classify_zip(filename, instance_dir, current_app.config['CLASSIFIER_FOLDER'])
        print "analyzer got predicted activity: %s and UTime: %s from classify_zip." % (predicted_activity,UTime);
        msg = ''
        success = True;
        pass;
    except Exception as e:
        predicted_activity = 'none'
	msg = e.message
        success = False;
        print msg
	try:
	    UTime = filename[:filename.find('-')]
	except:
	    UTime = 0
            pass;
        pass;

    return_string = json.dumps( {'api_type':'feedback_upload','filename':uploaded_file.filename,'success': success, 'predicted_activity': predicted_activity, 'timestamp': int(UTime), 'msg': msg } );

    print "Analyzer returning message:";
    print return_string;
    return return_string;

@analyzer_api.route( '/feedback' )
def handle_feedback():
    print 'feedback()'
    '''
        Handles saving feedback that is sent from the app.

        Parameters
        ----------
        uuid                - UUID of device sending the feedback
								
	  timestamp			- Timestamp of activity in question

        predicted_activity  - The activity our system predicted

        corrected_activity    - The activity the user corrected

        secondary_activities - The set of user secondary activities (separated with commas)

        mood - The mood of the user

        label_source - a string to describe in which mechanism the user supplied these labels

        Results
        -------
        JSON success if all params are present and correctly parsed
        JSON failure if something is not present or incorrectly parsed
    '''
#    connection = pymongo.Connection()
#    rmwdb = connection[ 'rmw' ]
#    feedback = rmwdb.feedback

    fback = {}
    try:
        # Check for required parameters
        if 'uuid' not in request.args:
            raise Exception( 'Missing uuid' )
        if 'timestamp' not in request.args:
		raise Exception( 'Missing timestamp')
        if 'predicted_activity' not in request.args:
            raise Exception( 'Missing predicted_activity' )
        if 'corrected_activity' not in request.args:
            raise Exception( 'Missing corrected_activity' )
        if 'secondary_activities' not in request.args:
            raise Exception( 'Missing secondary_activities' )
        if 'moods' not in request.args:
            raise Exception( 'Missing moods' )
        if 'label_source' not in request.args:
            raise Exception( 'Missing label_source' )

        fback[ 'uuid' ]                 	= request.args.get( 'uuid' )
        fback[ 'timestamp' ]		    	= request.args.get( 'timestamp' ) 
        fback[ 'predicted_activity' ]   	= request.args.get( 'predicted_activity' ).upper()
        fback[ 'corrected_activity' ]     	= request.args.get( 'corrected_activity' ).upper()
        fback[ 'secondary_activities' ]         = request.args.get( 'secondary_activities' ).upper().split( ',' )
        fback[ 'moods' ]                        = request.args.get( 'moods' ).upper().split( ',' )
        fback[ 'label_source' ]                 = request.args.get( 'label_source' ).upper();

        UUID 	= str(fback['uuid'])
        UTime 	= str(fback['timestamp'])
        instance_dir = get_and_create_upload_instance_dir(UUID,UTime);
        feats_path 	= os.path.join(current_app.config['CLASSIFIER_FOLDER'],'feats',UUID,UTime)
        if not os.path.exists(feats_path):
            raise Exception( 'Can''t find corresponding data on the server' )
        else:
            feedback_file = os.path.join(instance_dir,'feedback');
            if os.path.exists(feedback_file):
                fp_in = open(feedback_file,'r');
                old_fback = json.load(fp_in);
                fp_in.close();
                
                if type(old_fback) == list:
                    fbacks = old_fback;
                    pass;
                else:
                    fbacks = [old_fback];
                    pass;
                pass;
            else:
                # No older feedback file:
                fbacks = [];
                pass;

            # Add the new feedback to the feedback history:
            fbacks.append(fback);

            fp = open(feedback_file,'w')
            json.dump( fbacks, fp)
            fp.close()
    

        sys.stdout.flush()
    except Exception, exception:
        print exception
        sys.stdout.flush()
        return json.dumps( {'api_type':'feedback','success': False, 'timestamp': int(UTime), 'msg': str( exception ) } )

    return json.dumps( {'api_type':'feedback','success': True, 'timestamp': int(UTime) } ) 
