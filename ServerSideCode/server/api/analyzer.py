'''
    analyze.py

    API functions to handle data analyzing and feedback from the device
'''
import os
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
    #if uploaded_file and allowed_file( uploaded_file.filename ):
        filename = secure_filename( uploaded_file.filename )

        uploaded_file.save( os.path.join( current_app.config['UPLOAD_FOLDER'], filename ) )
        print 'saved ', filename
	
	#now predict the activity

        predicted_activity, UTime = activity_analyzer.classify_zip(filename, current_app.config['UPLOAD_FOLDER'], current_app.config['CLASSIFIER_FOLDER'])
        msg = ''
	return json.dumps( {'success': True, 'predicted_activity': predicted_activity, 'timestamp': int(UTime), 'msg': msg } )
    except Exception as e:
        predicted_activity = 'none'
	msg = e.message
        print msg
	try:
	    UTime = filename[:filename.find('-')]
	except:
	    UTime = 0
	return json.dumps( {'success': False, 'predicted_activity': 'none', 'timestamp': int(UTime), 'msg': msg } )

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
        if 'mood' not in request.args:
            raise Exception( 'Missing mood' )

        fback[ 'uuid' ]                 	= request.args.get( 'uuid' )
        fback[ 'timestamp' ]		    	= request.args.get( 'timestamp' ) 
        fback[ 'predicted_activity' ]   	= request.args.get( 'predicted_activity' ).upper()
        fback[ 'corrected_activity' ]     	= request.args.get( 'corrected_activity' ).upper()
        fback[ 'secondary_activities' ]         = request.args.get( 'secondary_activities' ).upper().split( ',' )
        fback[ 'mood' ]                         = request.args.get( 'mood' ).upper()

        UUID 	= str(fback['uuid'])
        UTime 	= str(fback['timestamp'])
        fpath 	= os.path.join(current_app.config['CLASSIFIER_FOLDER'],'feats',UUID,UTime)
        if not os.path.exists(fpath):
            raise Exception( 'Can''t find corresponding data on the server' )
        else:
            fp = open(os.path.join(fpath,'feedback'),'w')
            json.dump( fback, fp)
            fp.close()
    
#        feedback.insert( fback )        
        sys.stdout.flush()
    except Exception, exception:
        print exception
        sys.stdout.flush()
        return json.dumps( {'success': False, 'msg': str( exception ) } )

    return json.dumps( {'success': True } ) 
