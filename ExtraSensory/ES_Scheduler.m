//
//  ES_Scheduler.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/1/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//
//

#import "ES_Scheduler.h"
#import "ES_SensorManager.h"
#import "ES_DataBaseAccessor.h"
#import "ES_HomeViewController.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_SensorSample.h"
#import "ES_Activity.h"
#import "ES_Settings.h"
#import "ES_SoundWaveProcessor.h"

#define HF_PRE_FNAME        @"HF_PRE_DATA.txt"
#define HF_DUR_FNAME        @"HF_DUR_DATA.txt"

@interface ES_Scheduler()

@property (nonatomic, strong) ES_SensorManager *sensorManager;

@property int counter;

@property double waitTime;

@property (nonatomic, strong) ES_HomeViewController *homeViewController;

@property (nonatomic, strong) NSMutableArray *predictions;

@property NSTimer *timer;

@end


@implementation ES_Scheduler

@synthesize sensorManager = _sensorManager;

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

- (ES_AppDelegate *) appDelegate
{
    return (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void) sampleSaveSendCycler: (ES_HomeViewController *) homeViewController
{
    self.homeViewController = homeViewController;
    
    NSLog( @"\n\nStart" );
    
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
                //NSLog(@"Background time Remaining: %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
                [NSThread sleepForTimeInterval:30]; //wait for 30 sec
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
    
    [self firstOp];
    NSLog( @"time between sampling = %f", [self.user.settings.timeBetweenSampling doubleValue] );
    self.timer = [NSTimer scheduledTimerWithTimeInterval: [self.user.settings.timeBetweenSampling doubleValue]
                                                      target: self
                                                    selector: @selector(firstOp)
                                                    userInfo: nil
                                                     repeats: YES];
}

- (void) turnOffRecording
{
    NSLog(@"[scheduler] turnOffRecording");
    [self setIsOn: NO];
    [self.sensorManager turnOffRecording];
    [self.timer invalidate];
    self.timer = nil;
    
}

- (void) activeFeedback: (ES_Activity *) activity
{
    NSLog( @"\n\nStart active feedback sample" );
    
    [self.timer invalidate]; //turn off auto-sampling timer
    self.timer = nil;
    [self firstOpActive: activity];
    
    // turn auto-sampling timer back on
    self.timer = [NSTimer scheduledTimerWithTimeInterval: [self.user.settings.timeBetweenSampling doubleValue]
                                                      target: self
                                                selector: @selector(firstOp)
                                                    userInfo: nil
                                                     repeats: YES];
}

-(void) firstOp
{
    NSLog(@"Record Sensors");
    [self.sensorManager setCurrentActivity: nil];
    [self.sensorManager record];
}

-(void) firstOpActive: (ES_Activity *) activity
{
    NSLog(@"Record Sensors");
    [self.sensorManager setCurrentActivity: activity];
    [self.sensorManager record];
}


@end

