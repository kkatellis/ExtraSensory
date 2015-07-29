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
//#define IOS_WATCHAPP_UUID @"668eb2d2-73dd-462d-b079-33f0f70ad3d0"
#define IOS_WATCHAPP_UUID @"7dee2ab7-366e-4f02-aea0-265d66518fb6"
#define RAW_WATCH_MAX_SAMPLES 500
#define WATCH_SAMPLING_PERIOD 40


@interface ES_WatchProcessor() <PBPebbleCentralDelegate>

@property (nonatomic, strong) PBWatch *myWatch;
@property (nonatomic, strong)  ES_AppDelegate *appDelegate;
@property (nonatomic, strong) NSObject *receiveUpdateHandler;
@property (nonatomic, strong) ES_SensorManager *sensorManager;
@property (nonatomic, strong) NSMutableDictionary *userInfo;
@property (nonatomic, strong) NSMutableArray *messageQueue;

@end

@implementation ES_WatchProcessor

@synthesize messageQueue = _messageQueue;
BOOL _stopCalled = NO;
BOOL _sendingMessage = NO;

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
    if (!self.myWatch) {
        [PBPebbleCentral setDebugLogsEnabled:YES];
        [[PBPebbleCentral defaultCentral] setDelegate:self];
    
        // set app id of current watch
        uuid_t myAppUUIDbytes;
        NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:IOS_WATCHAPP_UUID];
        [myAppUUID getUUIDBytes:myAppUUIDbytes];
    
        [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
    
        // connects to last connected watch
        self.myWatch = [[PBPebbleCentral defaultCentral] lastConnectedWatch];
    }
    
    [self.myWatch appMessagesLaunch:^(PBWatch *watch, NSError *error) {
        if (!error) {
            NSLog(@"[WP] Successfully launched app.");
        }
        
        else {
            NSLog(@"[WP] Error launching app - Error: %@", error);
        }
        }
     ];
    [self initializeMessageQueue];
    
}

-(void)receiveDataFromWatch
{
    [self.watchAccTimestamps removeAllObjects];
    [self.mutableWatchAccX removeAllObjects];
    [self.mutableWatchAccY removeAllObjects];
    [self.mutableWatchAccZ removeAllObjects];
    [self.compassTimestamps removeAllObjects];
    [self.compassHeadings removeAllObjects];
    [self startWatchCollection];
}

- (void) registerReceiveHandler
{
    if (self.receiveUpdateHandler) {
        NSLog(@"[WP] Unregistring old handler, before registring new handler");
        [self.myWatch appMessagesRemoveUpdateHandler:self.receiveUpdateHandler];
    }
    
    [self registerReceiveHandlerAssumingAlreadyUnregistered];
}

-(void)registerReceiveHandlerAssumingAlreadyUnregistered
{
    NSLog(@"[WP] Registring new receive-update handler");
    self.receiveUpdateHandler = [self.myWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
        // code to handle activity update events
        NSString *answer;
        NSInteger timereference = 0;
        if([update count] == 1) {
            answer = [NSString stringWithFormat:@"%@", [update objectForKey:WATCH_MESSAGE_KEY]];
            
            if ([answer isEqualToString:YES_ANSWER] && [_userInfo valueForKey:FOUND_VERIFIED_KEY]) {
                
                [[self appDelegate] pushActivityEventFeedbackViewWithUserInfo:_userInfo userAlreadyApproved:YES approvalFromWatch:YES];
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
            NSLog(@"===== initializing acc arrays");
            self.watchAccTimestamps = [[NSMutableArray alloc] init];
            self.mutableWatchAccX = [[NSMutableArray alloc] init];
            self.mutableWatchAccY = [[NSMutableArray alloc] init];
            self.mutableWatchAccZ = [[NSMutableArray alloc] init];
        }
        if (!(self.compassTimestamps)) {
            NSLog(@"===== initializing compass arrays");
            self.compassTimestamps = [[NSMutableArray alloc] init];
            self.compassHeadings = [[NSMutableArray alloc] init];
        }
       // NSLog(@"[WP] Recieved another watch accelerometer/compass update: %@",update);
        for (id key in [[update allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
            NSString *temp = [NSString stringWithFormat:@"%@", [update objectForKey:key]];
            NSArray *xyz = [temp componentsSeparatedByString:@","];
            //NSLog(@"watch message: %@:%@", key, temp);
            if ([xyz count] == 3) {
                // Then this is an update of accelerometer measurements:
                NSNumber *timeRef = [NSNumber numberWithInteger: timereference + WATCH_SAMPLING_PERIOD * ([key integerValue] - 1)];
                NSNumber *aNum0 = [NSNumber numberWithInteger: [xyz[0] integerValue]];
                NSNumber *aNum1 = [NSNumber numberWithInteger: [xyz[1] integerValue]];
                NSNumber *aNum2 = [NSNumber numberWithInteger: [xyz[2] integerValue]];
                [self.watchAccTimestamps addObject:timeRef];
                [self.mutableWatchAccX addObject:aNum0];
                [self.mutableWatchAccY addObject:aNum1];
                [self.mutableWatchAccZ addObject:aNum2];
                
            } else {
                NSArray *th = [temp componentsSeparatedByString:@":"];
                if ([th count] == 2) {
                    // Then we have an update of compass heading:
                    // NSLog(@"[WP] got compass update, time: %@ and value %@ degrees", key, xyz);
                    [self.compassTimestamps addObject:[NSNumber numberWithInteger:[th[0] integerValue]]];
                    [self.compassHeadings addObject:[NSNumber numberWithInteger:[th[1] integerValue]]];
                } else if ([key integerValue] == 0) {
                    // Then we have a timestamp
                    timereference = [temp integerValue];
                    //[self.watchAccTimestamps addObject:[NSNumber numberWithInteger:[temp integerValue]]];
                } else {
                    NSLog(@"Don't know what this message is: %@", temp);
                }
            }
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
    [self addMessageToOutQueue:update];
}

-(void)startWatchCollection
{
    _stopCalled = NO;
    NSDictionary *update = @{ @(1):@"TURN ON" };
    [self addMessageToOutQueue:update];
}

-(void)nagUserWithQuestion: (NSDictionary*)question
{
    [self addMessageToOutQueue:question];
}

-(void)addMessageToOutQueue:(NSDictionary*)message
{
  //  NSLog(@"[WP] adding message to queue:%@", message);
    [self.messageQueue addObject:message];
    if (!_sendingMessage) {
        [self sendMessageFromOutQueue];
    } else {
  //      NSLog(@"[WP] already sending messages");
    }
}

- (void)sendMessageFromOutQueue
{
    if ([self.messageQueue count] > 0) {
        _sendingMessage = YES;
        // send first message in queue
      //  NSLog(@"[WP] queue count:%lu", (unsigned long)[self.messageQueue count]);
      //  NSLog(@"[WP] sending first message in queue:%@", [self.messageQueue objectAtIndex:0]);
        [self sendMessage:[self.messageQueue objectAtIndex:0]];
        [self.messageQueue removeObjectAtIndex:0];
    }
 //   NSLog(@"[WP] queue empty:%lu", (unsigned long)[self.messageQueue count]);
    
}

- (void)sendMessage:(NSDictionary*)message
{
    [self.myWatch appMessagesPushUpdate:message onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if (!error) {
            NSLog(@"[WP] Successfully sent message to watch: %@", update);
            _sendingMessage = NO;
            [self sendMessageFromOutQueue];
        }
        else {
            NSLog(@"[WP] Error sending message to watch: %@. update: %@", error, update);
            _sendingMessage = NO;
            [self sendMessageFromOutQueue];
        }
    }];
}

- (void) initializeMessageQueue
{
    if (self.messageQueue)
    {
        [self.messageQueue removeAllObjects];
    } else {
        self.messageQueue = [NSMutableArray arrayWithCapacity:2];
    }
    NSLog(@"[WP] initialized message queue: %@", self.messageQueue);
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    NSLog(@"[WP] Pebble connected: %@", [watch name]);
    self.myWatch = watch;
    [self launchWatchApp];
    [self registerReceiveHandler];
    [self initializeMessageQueue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WatchConnection" object:self];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    NSLog(@"[WP] Pebble disconnected: %@", [watch name]);
    
    if (self.myWatch == watch || [watch isEqual:self.myWatch]) {
        self.myWatch = nil;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WatchConnection" object:self];
}

- (BOOL) isConnectedToWatch {
    if (!self.myWatch) {
        return NO;
    }
    
    return [self.myWatch isConnected];
}

@end