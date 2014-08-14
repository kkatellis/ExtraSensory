'''
activity_analyzer test
'''

import activity_analyzer

filename = '1380839895-008D3E32-AB00-490D-88EA-D6709A87C9FB.zip'
upload_folder = '/Library/WebServer/Documents/rmw/feedback'
classifier_folder = '/Library/WebServer/Documents/rmw/classifier'

predicted_activity = activity_analyzer.classify_zip(filename, upload_folder, classifier_folder)
print predicted_activity