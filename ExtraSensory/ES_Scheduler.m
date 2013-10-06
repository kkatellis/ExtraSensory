//
//  ES_Scheduler.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/1/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_Scheduler.h"
#import "ES_SensorManager.h"
#import "ES_NetworkAccessor.h"
#import "ES_DataBaseAccessor.h"
#import "ES_HomeViewController.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_SensorSample.h"
#import "ES_Activity.h"

@interface ES_Scheduler()

@property (nonatomic, strong) ES_SensorManager *sensorManager;

@property (nonatomic, strong) ES_NetworkAccessor *networkAccessor;

@property int counter;

@property double waitTime;

@property (nonatomic, strong) ES_HomeViewController *homeViewController;

@property (nonatomic, strong) NSMutableArray *predictions;

@property NSTimer *timer;

@end


@implementation ES_Scheduler

@synthesize sensorManager = _sensorManager;

@synthesize networkAccessor = _networkAccessor;

@synthesize counter = _counter;

@synthesize isReady = _isReady;

@synthesize waitTime = _waitTime;

@synthesize predictions = _predictions;

@synthesize timer = _timer;

@synthesize user = _user;

- (ES_User *) user
{
    if (!_user)
    {
        ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _user = appDelegate.user;
    }
    return _user;
}

- (NSMutableArray *) predictions
{
    if (!_predictions)
    {
        _predictions = [NSMutableArray new];
    }
    return _predictions;
}


- (double) waitTime
{
    if (!_waitTime)
    {
        _waitTime = 10.0;
    }
    return _waitTime;
}

- (void) setWaitTime: (double)w
{
    _waitTime = w;
}

- (ES_SensorManager *) sensorManager
{
    if (!_sensorManager)
    {
        _sensorManager = [ES_SensorManager new];
        _sensorManager.locationManager = self.appDelegate.locationManager;
    }
    return _sensorManager;
}

- (ES_NetworkAccessor *) networkAccessor
{
    if (!_networkAccessor)
    {
        _networkAccessor = [ES_NetworkAccessor new];
    }
    return _networkAccessor;
}

- (ES_AppDelegate *) appDelegate
{
    return (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void) sampleSaveSendCycler: (ES_HomeViewController *) homeViewController
{
    self.homeViewController = homeViewController;
    
    NSLog( @"\n\nStart" );
    
    self.counter = 0;
    
    
    //2)Making background task Asynchronous
    if([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)])
    {
        NSLog(@"Multitasking Supported");
        
        __block UIBackgroundTaskIdentifier background_task;
        background_task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^ {
            
            //Clean up code. Tell the system that we are done.
            [[UIApplication sharedApplication] endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        }];
        
        
        //Putting All together**
        //To make the code block asynchronous
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //### background task starts
            NSLog(@"Running in the background\n");
            while(TRUE)
            {
                NSLog(@"Background time Remaining: %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
                [NSThread sleepForTimeInterval:150]; //wait for 1 sec
            }
            //#### background task ends
            
            //Clean up code. Tell the system that we are done.
            [[UIApplication sharedApplication] endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        });
    }
    else
    {
        NSLog(@"Multitasking Not Supported");
    }
    
    if (self.isReady)
    {
        [self setIsReady:NO];
        
        [self firstOp];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval: 300
                                                      target: self
                                                    selector: @selector(firstOp)
                                                    userInfo: nil
                                                     repeats: YES];
    }
    else
    {
        NSLog(@"not ready!");
    }
}




/*- (void) operationCycler
 {
 if ( self.counter == 0 )
 {
 [self firstOp];
 self.counter++;
 }
 else if (self.counter == 1 )
 {
 [self secondOp];
 self.counter++;
 }
 else if (self.counter == 2 )
 {
 [self thirdOp];
 self.counter = 0;
 }
 }*/

-(void) firstOp
{
    if (!self.isOn)
    {
        [self.timer invalidate];
        return;
    }
    
    NSLog(@"Record Sensors");
    
    [self.sensorManager record];
    
    NSLog(@"Back from sensor Recording");
    
    NSTimer *timer;
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 25
                                             target: self
                                           selector: @selector(thirdOp)
                                           userInfo: nil
                                            repeats: NO];
    
    
}

-(void) secondOp
{
    NSLog( @"sensor activity = %@", [self.sensorManager.user.activities lastObject]);
    
    NSLog(@"Zip Data");
    
    [ES_DataBaseAccessor zipData];
    
    NSTimer *timer;
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 5
                                             target: self
                                           selector: @selector(thirdOp)
                                           userInfo: nil
                                            repeats: NO];
    
}

-(void) thirdOp
{
    NSLog(@"upload");
    
    [self.networkAccessor upload];
    
    NSLog(@"back from uploading");
    
    [self setIsReady: YES];
}





@end

