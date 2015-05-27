//
//  ES_WatchProcessor.m
//  ExtraSensory
//
//  Created by Rafael Aguayo on 4/29/15.
//  Copyright (c) 2015 Bryan Grounds. All rights reserved.
//

#import "ES_WatchProcessor.h"

// Some constants:
#define YES_ANSWER @"YES"
#define NO_ANSWER @"NO"
#define WATCH_MESSAGE_KEY @42
#define FOUND_VERIFIED_KEY      @"foundVerified"
#define NAG_CHECK_TIMESTAMP_KEY @"nagCheckTimestamp"
#define MAIN_ACTIVITY_KEY       @"mainActivity"
#define SECONDARY_ACT_KEY       @"secondaryActivitiesStrings"
#define MOODS_KEY               @"moodsStrings"
#define LATEST_VERIFIED_KEY     @"latestVerifiedTimestamp"
#define IOS_WATCHAPP_UUID @"668eb2d2-73dd-462d-b079-33f0f70ad3d0"
#define RAW_WATCH_MAX_SAMPLES 500


@interface ES_WatchProcessor() <PBPebbleCentralDelegate>

@property (nonatomic, strong) PBWatch *myWatch;

@property (nonatomic, strong)  ES_AppDelegate *appDelegate;
@property (nonatomic, strong) ES_SensorManager *sensorManager;
@property (nonatomic, strong) NSMutableDictionary *userInfo;

@end

@implementation ES_WatchProcessor

BOOL _stopCalled = NO;

- (ES_AppDelegate *) appDelegate
{
    if (!_appDelegate)
    {
        _appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (ES_SensorManager *)sensorManager
{
    if (!_sensorManager)
    {
        _sensorManager = [ES_SensorManager new];
    }
    return _sensorManager;
}

-(void)launchWatchApp
{
    [PBPebbleCentral setDebugLogsEnabled:YES];
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    // set app id of current watch
    uuid_t myAppUUIDbytes;
    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:IOS_WATCHAPP_UUID];
    [myAppUUID getUUIDBytes:myAppUUIDbytes];
    
    [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
    
    // connects to last connected watch
    self.myWatch = [[PBPebbleCentral defaultCentral] lastConnectedWatch];
    
    [self.myWatch appMessagesLaunch:^(PBWatch *watch, NSError *error) {
        if (!error) {
            NSLog(@"[WATCHPROCESSOR] Successfully launched app.");
        }
        else {
            NSLog(@"[WATCHPROCESSOR] Error launching app - Error: %@", error);
        }
    }
     ];
    
}

-(void)nagUserWithQuestion: (NSDictionary*)question
{
    [self.myWatch appMessagesPushUpdate:question onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if (!error) {
            NSLog(@"[WP] Successfully sent question to watch.");
        }
        else {
            NSLog(@"[WP] Error sending question to watch: %@", error);
        }
 }];
}

-(void)receiveDataFromWatch
{
    [self.mutableWatchAccX removeAllObjects];
    [self.mutableWatchAccY removeAllObjects];
    [self.mutableWatchAccZ removeAllObjects];
    [self startWatchCollection];
}

-(void)registerReceiveHandler
{
    
    [self.myWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
//        NSLog(@"[WATCHPROCESSOR] Received message: %@", update);
        
        // code to handle activity update events
        NSString *answer;
            if([update count] == 1)
            {
                answer = [NSString stringWithFormat:@"%@", [update objectForKey:WATCH_MESSAGE_KEY]];
                
                if ([answer isEqualToString:YES_ANSWER] && [_userInfo valueForKey:FOUND_VERIFIED_KEY]) {
                [[self appDelegate] pushActivityEventFeedbackViewWithUserInfo:_userInfo userAlreadyApproved:YES];
                    [_userInfo removeAllObjects];
                return YES;
                }
                else if([answer isEqualToString:NO_ANSWER]) {
                    [_userInfo removeAllObjects];
                    return YES;
                }
                return YES;
            }
        
        if([self.mutableWatchAccX count] == RAW_WATCH_MAX_SAMPLES)
        {
            if(_stopCalled) {
                return NO;
            }
            [self stopWatchCollection];
            return NO;
        }
        if (!(self.mutableWatchAccX))
        {
            self.mutableWatchAccX = [[NSMutableArray alloc] init];
            self.mutableWatchAccY = [[NSMutableArray alloc] init];
            self.mutableWatchAccZ = [[NSMutableArray alloc] init];
        }
        //NSLog(@"[WP] Recieved another watch accelerometer update");
        for (id key in [[update allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
            NSString *temp = [NSString stringWithFormat:@"%@", [update objectForKey:key]];
            
            NSArray *xyz = [temp componentsSeparatedByString:@","];
            NSNumber  *aNum0 = [NSNumber numberWithInteger: [xyz[0] integerValue]];
            NSNumber  *aNum1 = [NSNumber numberWithInteger: [xyz[1] integerValue]];
            NSNumber  *aNum2 = [NSNumber numberWithInteger: [xyz[2] integerValue]];
            [self.mutableWatchAccX addObject:aNum0];
            [self.mutableWatchAccY addObject:aNum1];
            [self.mutableWatchAccZ addObject:aNum2];
        }
        return YES;
    }];
}

-(void) setUserInfo:(NSMutableDictionary *)userInfo
{
    _userInfo = userInfo;
}

-(void)closeWatchApp
{
    [self.myWatch appMessagesKill:^(PBWatch *watch, NSError *error) {
        if (!error) {
            NSLog(@"[WP] Successfully killed app.");
        }
        else {
            NSLog(@"[WP] Error killing app - Error: %@", error);
        }
    }];
}

-(void)stopWatchCollection
{
    if (_stopCalled){
        return;
    }
    _stopCalled = YES;
    NSDictionary *update = @{ @(1):@"TURN OFF" };
    [self.myWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if (!error) {
            NSLog(@"[WP] Successfully sent message to watch to stop accel collection.");
        }
        else {
            NSLog(@"[WP] Error sending message to stop accel collection: %@", error);
        }
    }];
}

-(void)startWatchCollection
{
    _stopCalled = NO;
    NSDictionary *update = @{ @(1):@"TURN ON" };
    [self.myWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if (!error) {
            NSLog(@"[WP]Successfully sent message to watch to start watch collection");
        }
        else {
            NSLog(@"[WP] Error sending message to start watch collection: %@", error);
        }
    }];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    NSLog(@"[WP] Pebble connected: %@", [watch name]);
    self.myWatch = watch;
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    NSLog(@"[WP] Pebble disconnected: %@", [watch name]);
    
    if (self.myWatch == watch || [watch isEqual:self.myWatch]) {
        self.myWatch = nil;
    }
}

- (BOOL) isConnectedToWatch {
    if (!self.myWatch) {
        return NO;
    }
    
    return [self.myWatch isConnected];
}

@end