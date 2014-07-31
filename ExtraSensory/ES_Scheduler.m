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
#import "ES_Activity.h"
#import "ES_Settings.h"
#import "ES_SoundWaveProcessor.h"
#import "ES_UserActivityLabels.h"

#define HF_PRE_FNAME        @"HF_PRE_DATA.txt"
#define HF_DUR_FNAME        @"HF_DUR_DATA.txt"

@interface ES_Scheduler()

@property (nonatomic, strong) ES_SensorManager *sensorManager;

@property int counter;

@property double waitTime;

@property (nonatomic, strong) ES_AppDelegate *appDelegate;

@property (nonatomic, strong) NSMutableArray *predictions;

@property NSTimer *timer;

@property NSTimer *naggingTimer;

@end


@implementation ES_Scheduler

@synthesize sensorManager = _sensorManager;

@synthesize waitTime = _waitTime;

@synthesize predictions = _predictions;

@synthesize timer = _timer;

@synthesize naggingTimer = _naggingTimer;

@synthesize user = _user;

- (ES_User *) user
{
    if (!_user)
    {
        _user = self.appDelegate.user;
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
    if (!_appDelegate)
    {
        _appDelegate = [[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (void) sampleSaveSendCycler
{
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
    
    // Set the first timer for user-nagging mechanizm:
    [self setTimerForNaggingCheckup];
}

- (void) turnOffRecording
{
    NSLog(@"[scheduler] turnOffRecording");
    self.appDelegate.dataCollectionOn = NO;
    [self.sensorManager turnOffRecording];
    [self.timer invalidate];
    self.timer = nil;
    
    [self.naggingTimer invalidate];
    self.naggingTimer = nil;
    
}

- (void) setTimerForNaggingCheckup
{
    NSNumber *timeBeforeNagCheckup = [NSNumber numberWithInt:60*3]; // This has to move to a property in user.settings (ES_Settings) ///////////////
    
    NSLog(@"=== Setting user-nagging timer for %@ seconds.",timeBeforeNagCheckup);
    self.naggingTimer = [NSTimer scheduledTimerWithTimeInterval:[timeBeforeNagCheckup doubleValue]
                                                         target: self
                                                       selector: @selector(userNaggingCheckup)
                                                       userInfo: nil
                                                        repeats: YES];
   
}

- (void) userNaggingCheckup
{
    NSDate *now = [NSDate date];
    NSLog(@"=== time: %@. Checking if it's time to nag the user",now);

    if (!self.appDelegate.dataCollectionOn)
    {
        //NSLog(@"=== data collection is off. Don't nag user!");
        //return;
    }

    // Look for latest user-corrected activity recently:
    NSNumber *recentPeriod = [NSNumber numberWithInteger:60*15]; // This has to be taken from some property in user.settings///////////
    ES_Activity *latestVerifiedActivity = [ES_DataBaseAccessor getLatestCorrectedActivityWithinTheLatest:recentPeriod];
    
    if (latestVerifiedActivity)
    {
        // Then ask user if they are still doing the same thing in the last x time:
        NSString *mainActivity = latestVerifiedActivity.userCorrection;
        NSSet *secondaryActivities = latestVerifiedActivity.userActivityLabels;
        NSString *mood = latestVerifiedActivity.mood;
        NSString *question = [NSString stringWithFormat:@"In the past %d minutes were you still %@",[recentPeriod integerValue]/60,mainActivity];
        if (secondaryActivities && [secondaryActivities count]>0)
        {
            NSString *secondaryString = [[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[secondaryActivities allObjects]] componentsJoinedByString:@","];
            question = [NSString stringWithFormat:@"%@ (%@)",question,secondaryString];
        }
        
        if (mood)
        {
            question = [NSString stringWithFormat:@"%@ and feeling %@",question,mood];
        }
        question = [NSString stringWithFormat:@"%@?",question];
        NSLog(@"=== should ask question:[%@]",question);
    }
    else
    {
        // Then ask the user to provide feedback:
        NSString *question = @"Can you update what you're doing now?";
        NSLog(@"=== should ask question: [%@]",question);
    }
    
    [self setTimerForNaggingCheckup];
}

- (void) activeFeedback: (ES_Activity *) activity
{
    NSLog( @"\n\nStart active feedback sample");
    self.appDelegate.mostRecentActivity = activity;
    
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

