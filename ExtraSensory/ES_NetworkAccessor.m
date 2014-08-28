//
//  ES_NetworkAccessor.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_NetworkAccessor.h"
#import "ES_DataBaseAccessor.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_Activity.h"
#import "ES_ActivityStatistic.h"
#import "ES_UserActivityLabels.h"

#define BOUNDARY        @"0xKhTmLbOuNdArY"

#define API_PREFIX      @"http://137.110.112.50:8080/api/"
#define API_UPLOAD      @"feedback_upload"
#define API_FEEDBACK    @"feedback?%@"

@interface ES_NetworkAccessor()

@property (nonatomic, strong) ES_AppDelegate* appDelegate;

@end

@implementation ES_NetworkAccessor

@synthesize recievedData = _recievedData;

@synthesize predictions = _predictions;

-(id) init
{
    self = [super init];
    if( self != nil ) {
    
        //--// Set up reachability class for wifi check
        wifiReachable = [Reachability reachabilityForLocalWiFi];
        isReady = YES;
    }
    return self;
}

-(ES_AppDelegate*) appDelegate
{
    if (!_appDelegate)
    {
        _appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (NSMutableArray *) predictions
{
    if (!_predictions)
    {
        _predictions = [NSMutableArray new];
    }
    return _predictions;
}

- (NSData *) recievedData
{
    if (!_recievedData)
    {
        _recievedData = [NSMutableData data];
    }
    return _recievedData;
}

- (void) sendFeedback: (ES_Activity *)activity
{
    [self apiCall:[NSString stringWithFormat:@"%@%@",API_PREFIX,API_FEEDBACK] withParams:activity];
    
}

- (void) apiCall:(NSString *)api withParams:(ES_Activity *)activity{
    // format the keys and values for the api call
    NSMutableArray *dataValues = [[NSMutableArray alloc] init];
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"predicted_activity",activity.serverPrediction]];
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"corrected_activity",activity.userCorrection]];
    
    NSString *secondaryActivitiesSingleString = [NSString stringWithFormat:@"%@",[[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[activity.userActivityLabels allObjects]] componentsJoinedByString:@","]];
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"secondary_activities",secondaryActivitiesSingleString]];
    
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"mood",activity.mood]];
    
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"uuid",activity.user.uuid]];
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"timestamp",activity.timestamp]];
    
    NSLog(@"[networkAccessor] sending api call with data: %@",dataValues);
    //NSString *combined = [[params objectForKey:key] componentsJoinedByString:@","];
    
    // setup final API url
    NSString *api_call = [dataValues componentsJoinedByString:@"&"];
    api_call = [api_call stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    api_call = [NSString stringWithFormat:api, api_call];
    NSLog(@"API call: %@", api_call);
    
    // setup connection
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:api_call] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    api_connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];
}


- (void) unsentItemsCheck
{
    NSString *storagePath = [ES_DataBaseAccessor zipDirectory];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:storagePath error:nil];
    NSPredicate *zipPredicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.zip'"];
    NSArray *storedZipFiles = [directoryContent filteredArrayUsingPredicate:zipPredicate];
    
    NSLog(@"=== Storage path has %lu zip files and network stack has %lu files.",(unsigned long)storedZipFiles.count,(unsigned long)self.appDelegate.networkStack.count);
    NSLog(@"=== Zip files in directory: %@",storedZipFiles);
    NSLog(@"=== files in network stack: %@",self.appDelegate.networkStack);
    
}

/**
 
 Uploads the given file. The file is compressed before beign uploaded.
 The data is uploaded using an HTTP POST command.
 
 */
- (void) upload
{
    NSLog( @"[networkAccessor] called for upload. Current network Stack size = %lu", (unsigned long)[self.appDelegate.networkStack count]);
    if (!isReady)
    {
        NSLog(@"[networkAccessor] notReady");
        return;
    }
    isReady = NO;
    NSString *file = [self.appDelegate getFirstOnNetworkStack];
    
    NSLog( @"upload: %@", file);
    if (!file)
    {
        NSLog( @"Nil file, not sending!");
        isReady = YES;
        return;
    }
        
    NSString *storagePath = [ES_DataBaseAccessor zipDirectory];
    NSString *fullPath = [ storagePath stringByAppendingString: file ];
    
    
    NSLog( @"[DataUploader] Attempting to upload %@", file );
    if( [wifiReachable currentReachabilityStatus] == ReachableViaWiFi )
    {
    
        NSData *data = [NSData dataWithContentsOfFile: fullPath];
    
        if( !data || [data length] == 0 )
        {
            NSLog(@"no data!");
        }
    
        NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@",API_PREFIX,API_UPLOAD]];
        NSURLRequest *urlRequest = [self postRequestWithURL: url
                                                boundry: BOUNDARY
                                                   data: data
                                               fileName: file];
        if( !urlRequest ) {
            NSLog( @"url request failed");
        }
    
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: urlRequest
                                                                   delegate: self.appDelegate.networkAccessor];
        self.appDelegate.currentlyUploading = YES;
        if (!connection) {
            NSLog( @"Connection Failed");
            isReady = YES;
            self.appDelegate.currentlyUploading = NO;
        }
    } else {
        NSLog(@"No Wifi, not uploading");
        isReady = YES;
    }
    
    // Now wait for the URL connection to call us back.
}

/**
 
 Creates a HTML POST request.
 
 */
- (NSURLRequest *)postRequestWithURL: (NSURL *)url
                             boundry: (NSString *)boundry
                                data: (NSData *)data
                            fileName: (NSString *) fileName
{
    // From http://www.cocoadev.com/index.pl?HTTPFileUpload
    NSMutableURLRequest *urlRequest =
    [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue: [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundry]
      forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *postData = [NSMutableData dataWithCapacity:[data length] + 512];
    
    [postData appendData: [[NSString stringWithFormat:@"--%@\r\n", boundry] dataUsingEncoding: NSUTF8StringEncoding]];
    
    [postData appendData: [[NSString stringWithFormat:
                            @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n\r\n", @"file", fileName]
                           dataUsingEncoding:NSUTF8StringEncoding]];
    
    [postData appendData:data];
    
    [postData appendData:
     [[NSString stringWithFormat:@"\r\n--%@--\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPBody:postData];
    
    //NSLog( @"urlRequest = %@", urlRequest);
    
    return urlRequest;
}

- (void) connection: (NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //NSLog( @"connectiondidReceiveResponse %@",response);
    
    [self.recievedData setLength: 0];
    
}

- (void) connection: (NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog( @"connection: didReceiveData: ...");
    [self.recievedData appendData:data];
}

- (void) connection: (NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog( @"Network Stack size = %lu", (unsigned long)[self.appDelegate.networkStack count]);
    connection = nil;
    self.recievedData = nil;
    NSLog( @"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLErrorKey]);
    self.appDelegate.currentlyUploading = NO;
    isReady = YES;
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    NSError *error;
    
    // Convert recieved data from data into characters, store in reply
    NSString *reply = [[NSString alloc] initWithData: self.recievedData
                                            encoding: NSUTF8StringEncoding];
    
    NSLog( @" reply = %@", [reply description]);
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData: self.recievedData options:NSJSONReadingMutableContainers error: &error];
    
    NSString *api_type = [response objectForKey:@"api_type"];
    if ([API_UPLOAD isEqualToString:api_type])
    {
        NSNumber *time = [NSNumber numberWithDouble: [[response objectForKey: @"timestamp"] doubleValue]];
        
        NSString *predictedActivity = [response objectForKey:@"predicted_activity"];
        if ([predictedActivity isEqualToString:@"none"])
        {
            NSLog(@"[networkAccessor] !!! Got response with 'none' as predicted activity for timestamp %@",time);
            predictedActivity = nil;
        }
        
        NSLog(@"[networkAccessor] Got response from api upload_feedback for time %@, with predicted activity %@", time,predictedActivity);
        
        NSString *uploadedZipFile = [response objectForKey:@"filename"];
        
        ES_AppDelegate *appDelegate = [self appDelegate];
        [appDelegate removeFromeNetworkStackAndDeleteFile:uploadedZipFile];
        isReady = YES;
        
        ES_Activity *activity = [ES_DataBaseAccessor getActivityWithTime: time ];

        if (activity)
        {
            [appDelegate.predictions insertObject:activity atIndex:0];
        
            // set the predicted activity for our local Activity object
            [activity setValue: predictedActivity forKey: @"serverPrediction" ];
        
            connection = nil;
        
            [[NSNotificationCenter defaultCenter] postNotificationName: @"Activities" object: nil ];

            // Check if there is already some non-trivial labels that should be sent for this activity:
            if ([self isThereUserUpdateForActivity:activity])
            {
                NSLog(@"=== Activity that just received prediction already has some user-labeling, so sending it now...");
                [self sendFeedback:activity];
            }
            
        }
        else
        {
            NSLog(@"[networkAccessor] Didn't find an existing activity record for timestamp: %@ (%@).",time,[NSDate dateWithTimeIntervalSince1970:[time doubleValue]]);
        }
        
        //[appDelegate updateNetworkStackFromStorageFilesIfEmpty];
        NSLog(@"[networkAccessor] network stack size (1): %lu",(unsigned long)appDelegate.networkStack.count);
        if ( [appDelegate.networkStack count] > 0)
        {
            NSLog(@"[networkAccessor] Still items in network stack. Calling upload...");
            [self upload];
        }
        NSLog(@"[networkAccessor] network stack size (2): %lu",(unsigned long)appDelegate.networkStack.count);
    }
    else
    {
        NSLog(@"=== not response from upload, but %@",api_type);
    }
    self.appDelegate.currentlyUploading = NO;
}


- (BOOL) isThereUserUpdateForActivity:(ES_Activity *)activity
{
    if (activity.userCorrection)
    {
        return YES;
    }
    if (activity.mood)
    {
        return YES;
    }
    if (activity.userActivityLabels && activity.userActivityLabels.count > 0)
    {
        return YES;
    }
    
    return NO;
    
}


@end
