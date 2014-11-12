'''
settings.py
    
Contains the settings for the Flask application. 
See http://flask.pocoo.org/docs/config/ for more details. 
'''

import os

class Config( object ):
    DEBUG = False
    TESTING = False
    SECRET_KEY = 't;\xfaB\xde\x87\x9a\xe4\xab\x0cOB\xf6\xd6b\x8d\x1e\x98G\x16\xfa\xc6\x98\xe2'
    CACHE_TYPE = 'simple'

class Dev( Config ):
    DEBUG = True
    #SQLALCHEMY_DATABASE_URI = 'sqlite:///../tmp/dev.db'
    classpath = os.getcwd() + '/scripts/ActivityAnalyzer/bin'
    ANALYZER_PATH = 'java -classpath "' + classpath + '" ActivityAnalyzer %s'
    UPLOAD_FOLDER = os.getcwd() + '/feedback'
    CLASSIFIER_FOLDER = os.getcwd() + '/classifier'

class Production( Config ):
    #SQLALCHEMY_DATABASE_URI = 'sqlite:///../tmp/dev.db'
    ANALYZER_PATH = 'java -classpath "/Library/WebServer/Documents/rmw/scripts/ActivityAnalyzer/bin" ActivityAnalyzer %s'
#    UPLOAD_FOLDER = '/Library/WebServer/Documents/rmw/feedback'
    UPLOAD_FOLDER = '/Library/WebServer/Documents/rmw/user_input'
    CLASSIFIER_FOLDER = '/Library/WebServer/Documents/rmw/classifier'

class Testing( Config ):
    TESTING = True
