import datetime
import pymongo

from flask import Flask, render_template, request

# Import API functions
from server.api.analyzer import analyzer_api
from server.api.misc import misc_api

from server.cache import cache
from server.db import db

# Flask components
MAIN  = Flask( __name__ )

def gunicorn_app( environ, start_response ):
	return MAIN( environ, start_response )

def create_app( settings = 'server.settings.Dev' ):
    print 'creating app'

    MAIN.config.from_object( settings )
    
    # Initialize db/cache with app
    db.init_app( MAIN )
    cache.init_app( MAIN )
    
    # Register apis
    MAIN.register_blueprint( analyzer_api, url_prefix='/api' )
    MAIN.register_blueprint( misc_api, url_prefix='/api' )
    
    print 'registered blueprint'    
    return MAIN

def activity_stats( results ):
    activity_counts = {}
    activity_per_day = {}
    packets_per_day = {}

    all_results = []
    for res in results:
        all_results.append( res )

        timestamp = res[ 'timestamp' ]
        time_key = '%d/%d' % ( timestamp.month, timestamp.day )

        # Count the number of packets per day
        if time_key not in packets_per_day:
            packets_per_day[ time_key ] = 0
        else:
            packets_per_day[ time_key ] += 1
            
        # Count the number of activities per day
        if time_key not in activity_per_day:
            activity_per_day[ time_key ] = set()
        else:
            for x in res[ 'CURRENT_ACTIVITY' ]:
                activity_per_day[ time_key ].add( x )

        # Count the number of total activities
        for activity in res[ 'CURRENT_ACTIVITY' ]:

            if activity not in activity_counts:
                activity_counts[ activity ] = 0

            activity_counts[ activity ] += 1

    # Convert the activity sets to actual counts
    for key in activity_per_day:
        activity_per_day[ key ] = len( activity_per_day[ key ] )

    return ( all_results, activity_counts, activity_per_day, packets_per_day ) 

@MAIN.route( '/stats/search', methods=[ 'GET' ] )
def stats_search():
    connection = pymongo.Connection()
    rmwdb = connection[ 'rmw' ]
    feedback = rmwdb.feedback

    uuid        = request.args.get( 'uuid', '' )
    date_begin  = request.args.get( 'dbegin', None )
    date_end    = request.args.get( 'dend', None )

    params = { 'uuid': { '$regex': '^%s' % ( uuid ) } }

    if date_end is not None and date_begin is not None and \
        len( date_end ) > 0 and len( date_begin ) > 0:
        params[ 'timestamp' ] = { '$lt': datetime.datetime.strptime( date_end, '%m/%d/%Y' ) }
        params[ 'timestamp' ] = { '$gt': datetime.datetime.strptime( date_begin, '%m/%d/%Y' ) }
    
    results = feedback.find( params ).sort( 'timestamp', direction=pymongo.DESCENDING )

    all_results, activity_counts, activity_per_day, packets_per_day = activity_stats( results )

    return render_template( 'stats_search.html', results=all_results, \
                                                    uuid=uuid, \
                                         activity_counts=activity_counts, \
                                        activity_per_day=activity_per_day, \
                                         packets_per_day=packets_per_day )

@MAIN.route( '/stats', methods=[ 'GET' ] )
def stats():
    connection = pymongo.Connection()
    rmwdb = connection[ 'rmw' ]
    feedback = rmwdb.feedback

    results = feedback.find()
    count  = feedback.find().count()
    recent = feedback.find().sort( 'timestamp', direction=pymongo.DESCENDING ).limit( 10 )

    all_results, activity_counts, activity_per_day, packets_per_day = activity_stats( results )

    return render_template( 'stats.html', count=count, recent=recent, \
                                            activity_counts=activity_counts, \
                                           activity_per_day=activity_per_day, \
                                            packets_per_day=packets_per_day )
    
@MAIN.route( '/' )
@MAIN.route( '/index.html' )
def index():
    return render_template( 'index.html' )
