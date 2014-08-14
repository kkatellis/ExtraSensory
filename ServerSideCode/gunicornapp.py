import sys, os

# Only need to set this on Dreamhost
PYTHON_INTERP 	 = None # "/home/athlabs/env/bin/python"
PROJECT_NAME 	 = '/Library/WebServer/Documents'
PROJECT_SETTINGS = 'server.settings.Production'

if PYTHON_INTERP and sys.executable != PYTHON_INTERP: 
	os.execl( PYTHON_INTERP, PYTHON_INTERP, *sys.argv )

os.chdir( PROJECT_NAME )
sys.path.append( os.getcwd() )
print os.getcwd()

from server import create_app
application = create_app( PROJECT_SETTINGS )
