import csv
import json
import os
import pymongo
import urllib, urllib2
import sys
import time

ECHONEST_API_KEY = '6JRJVZ4BDYWXSPUGZ'

ECHO_API 	= 'http://developer.echonest.com/api/v4/song/search?%s'
ECHO_SEARCH = { 'api_key': 	ECHONEST_API_KEY,
				'format': 	'json',
				'results':	10,
				'bucket': 	'id:rdio-us-streaming' }

def get_rdio_id( artist, track ):
	query = dict( ECHO_SEARCH )
	query[ 'artist' ] = artist
	query[ 'title'  ] = track

	results = json.loads( \
				urllib2.urlopen( \
					ECHO_API % ( urllib.urlencode( query ) ) \
				).read() )
	
	for song in results[ 'response' ][ 'songs' ]:
		if len( song[ 'foreign_ids' ] ) > 0:
			fids = song[ 'foreign_ids' ]
			for fid in fids:
				if fid[ 'catalog' ] == 'rdio-us-streaming':
					return fid[ 'foreign_id'].split( ':' )[2]
	return None