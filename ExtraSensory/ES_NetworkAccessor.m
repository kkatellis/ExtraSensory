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
#import "ES_ActivitiesStrings.h"
//#import "ES_UserActivityLabels.h"

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
        [wifiReachable startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:wifiReachable];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadIfNecessaryAfterNetworkStackChanged) name:@"NetworkStackSize" object:[self appDelegate]];
        
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

- (NetworkStatus) reachabilityStatus
{
    return [wifiReachable currentReachabilityStatus];
}

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if ([self reachabilityStatus] == ReachableViaWiFi)
    {
        NSLog(@"[networkAccessor] WiFi is now available. Set timer to call upload in 3 seconds.");
        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(upload) userInfo:nil repeats:NO];
    }
    else
    {
        NSLog(@"[networkAccessor] Reachability change detected, but WiFi is not available.");
    }
}

- (NSData *) recievedData
{
    if (!_recievedData)
    {
        _recievedData = [NSMutableData data];
    }
    return _recievedData;
}

- (NSString *) getStringFromLabelSourceCodeNumber:(NSNumber *)labelSourceNumebr
{
    if (!labelSourceNumebr)
    {
        return @"missing";
    }
    
    ES_LabelSource labelSource = [labelSourceNumebr integerValue];
    switch (labelSource)
    {
        case ES_LabelSourceDefault: return @"default";break;
        case ES_LabelSourceActiveFeedbackStart: return @"active_feedback_start";break;
        case ES_LabelSourceActiveFeedbackContinue: return @"active_feedback_continue";break;
        case ES_LabelSourceHistory: return @"history";break;
        case ES_LabelSourceNotificationBlank: return @"notification_blank";break;
        case ES_LabelSourceNotificationAnswerCorrect: return @"notification_answer_correct";break;
        case ES_LabelSourceNotificationAnsewrNotExactly: return @"notification_answer_not_exactly";break;
            
        default:
            NSLog(@"[network] !!! Found unfamiliar label-source value: %d",labelSource);
            return [NSString stringWithFormat:@"unfamiliar_value_%d",labelSource];
            break;
    }
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
    
    NSString *secondaryActivitiesSingleString = [NSString stringWithFormat:@"%@",[[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[activity.secondaryActivities allObjects]] componentsJoinedByString:@","]];
    NSString *moodsSingleString = [NSString stringWithFormat:@"%@",[[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[activity.moods allObjects]] componentsJoinedByString:@","]];
    
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"secondary_activities",secondaryActivitiesSingleString]];
    
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"moods",moodsSingleString]];
    
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"uuid",activity.user.uuid]];
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"timestamp",activity.timestamp]];
    
    [dataValues addObject:[NSString stringWithFormat:@"%@=%@",@"label_source",[self getStringFromLabelSourceCodeNumber:activity.labelSource]]];
    
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


- (void) uploadIfNecessaryAfterNetworkStackChanged
{
    if (self.appDelegate.networkStack.count > 0)
    {
        NSLog(@"[networkAccessor] Network stack size changed.");
        if (isReady)
        {
            NSLog(@"[networkAccessor] Ready. Calling 'upload'");
            [self upload];
        }
    }
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
    
    if (!file)
    {
        NSLog( @"[networkAccessor] No file to upload. Nothing to send.");
        isReady = YES;
        return;
    }
        
    NSString *storagePath = [ES_DataBaseAccessor zipDirectory];
    NSString *fullPath = [ storagePath stringByAppendingString: file ];
    
    
    NSLog( @"[networkAccessor] Attempting to upload %@", file );
    if( [self reachabilityStatus] == ReachableViaWiFi )
    {
    
        NSData *data = [NSData dataWithContentsOfFile: fullPath];
    
        if( !data || [data length] == 0 )
        {
            NSLog(@"[networkAccessor] !!! no data!");
        }
        else
        {
            NSLog(@"[networkAccessor] Loaded zip file's data");
        }
    
        NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@",API_PREFIX,API_UPLOAD]];
        NSURLRequest *urlRequest = [self postRequestWithURL: url
                                                boundry: BOUNDARY
                                                   data: data
                                               fileName: file];
        if( !urlRequest ) {
            NSLog( @"[networkAccessor] url request failed");
        }
        else
        {
            NSLog(@"[networkAccessor] url request created");
        }
    
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: urlRequest
                                                                   delegate: self.appDelegate.networkAccessor];
        self.appDelegate.currentlyUploading = YES;
        if (!connection) {
            NSLog( @"[networkAccessor] !!! Connection Failed");
            isReady = YES;
            self.appDelegate.currentlyUploading = NO;
        }
        else
        {
            NSLog(@"[networkAccessor] Got connection. Waiting for reply...");
        }
    }
    else
    {
        NSLog(@"[networkAccessor] No Wifi, not uploading");
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
    NSLog( @"[networkAccessor] connectiondidReceiveResponse.");
    
    [self.recievedData setLength: 0];
    
}

- (void) connection: (NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog( @"[networkAccessor] connection: didReceiveData");
    [self.recievedData appendData:data];
}

- (void) connection: (NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog( @"[networkAccessor] Network Stack size = %lu", (unsigned long)[self.appDelegate.networkStack count]);
    connection = nil;
    self.recievedData = nil;
    NSLog( @"[networkAccessor] !!! Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLErrorKey]);
    self.appDelegate.currentlyUploading = NO;
    isReady = YES;
    [self upload];
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    NSError *error;
    
    // Convert recieved data from data into characters, store in reply
    NSString *reply = [[NSString alloc] initWithData: self.recievedData
                                            encoding: NSUTF8StringEncoding];
    
    NSLog( @"[networkAccessor] Got reply = %@", [reply description]);
    
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
        
        if ([predictedActivity isEqualToString:@"Driving"])
        {
            predictedActivity = @"Sitting";
            NSLog(@"[networkAccessor] Changing the predicted activity driving (deprecated) to be sitting");
        }
        if ([predictedActivity isEqualToString:@"Standing"])
        {
            predictedActivity = @"Standing in place";
            NSLog(@"[networkAccessor] Changing the predicted activity standing (deprecated) to be 'Standing in place'");
        }

        NSString *uploadedZipFile = [response objectForKey:@"filename"];
        
        ES_AppDelegate *appDelegate = [self appDelegate];
        BOOL uploadSuccess = [@"true" isEqualToString:[response objectForKey:@"success"]];
        if (uploadSuccess) {
            [appDelegate removeFromeNetworkStackAndDeleteFile:uploadedZipFile];
        }
        else {
            [appDelegate markStrikeForUploadingFile:uploadedZipFile];
        }
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
                NSLog(@"[networkAccessor] Activity that just received prediction (timestamp %@) already has some user-labeling, so sending it now...",time);
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
        NSLog(@"[networkAccessor] Response is not for the 'upload' api, but '%@'",api_type);
    }
    self.appDelegate.currentlyUploading = NO;
}


- (BOOL) isThereUserUpdateForActivity:(ES_Activity *)activity
{
    if (activity.userCorrection)
    {
        return YES;
    }
    if (activity.moods && activity.moods.count > 0)
    {
        return YES;
    }
    if (activity.secondaryActivities && activity.secondaryActivities.count > 0)
    {
        return YES;
    }
    
    return NO;
    
}


@end
