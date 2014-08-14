'''
    misc.py

    Miscellaneous API functions.
'''
import json

from flask import Blueprint, request, render_template
from server.helper import get_rdio_id

misc_api = Blueprint( 'misc_api', __name__ )

@misc_api.route( '/has_rdio_id', methods=[ 'GET' ] )
def check_page():
    '''
        Returns a page to check for RDIO ids
    '''
    return render_template( 'idcheck.html' )

@misc_api.route( '/has_rdio_id', methods=[ 'POST' ] )
def check_result():
    '''
        Process an RDIO id check
    '''
    artist = request.form[ 'artist' ]
    track  = request.form[ 'track' ]

    rdio_id = get_rdio_id( artist, track )
    if rdio_id == None:
        return json.dumps( {'success': False} )
    return json.dumps( {'success': True, 'id': rdio_id } )