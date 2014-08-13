from flask.ext.sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def song_to_dict( song ):
    '''
        Converts a song entry into a dictionary. The song entry should be
        coming directly from a MongoDB database.

        @params
        song - Song entry from MongoDB

        @returns
        Dictionary object that can be converted into JSON
    '''
    newsong = {}

    # Copy over the attributes we need
    newsong[ 'dbid' ]    = str( song[ '_id' ] )
    newsong[ 'artist' ]  = song[ 'artist' ]
    newsong[ 'title' ]   = song[ 'track' ]
    newsong[ 'rdio_id' ] = song[ 'rdio_id' ]

    # Check to see if this song has an icon associated with it
    if song[ 'icon' ] is not None:
        newsong[ 'icon' ] = song[ 'icon' ]

    return newsong
