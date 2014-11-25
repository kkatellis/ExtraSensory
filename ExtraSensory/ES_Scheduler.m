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
#import "ES_ActivitiesStrings.h"
//#import "ES_UserActivityLabels.h"

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

@property (nonatomic) BOOL periodicRecordingMechanismIsOn;

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
        _appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (BOOL) isPeriodicRecordingMechanismOn
{
    return self.isPeriodicRecordingMechanismOn;
}

- (void) sampleSaveSendCycler
{
    if (self.periodicRecordingMechanismIsOn)
    {
        NSLog(@"[scheduler] Asked to turn on recording, but no need - it is already on.");
        return;
    }
    NSLog(@"[scheduler] turn On Recording");
    self.periodicRecordingMechanismIsOn = YES;
    
    //2)Making background task Asynchronous
    if([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)])
    {
        NSLog(@"[scheduler] Multitasking Supported");
        
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
            NSLog(@"[scheduler] Running in the background\n");
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
        NSLog(@"[scheduler] Multitasking Not Supported");
    }
    
    [self firstOp];
    NSLog( @"[scheduler] Time between sampling = %.0f", [self.user.settings.timeBetweenSampling doubleValue] );
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
    if (!self.periodicRecordingMechanismIsOn)
    {
        NSLog(@"[scheduler] Asked to turn off recording, but no need - it is already off.");
        return;
    }
    NSLog(@"[scheduler] turnOffRecording");
    self.periodicRecordingMechanismIsOn = NO;
    
    [self.sensorManager turnOffRecording];
    [self.timer invalidate];
    self.timer = nil;
    
    [self turnOffNaggingMechanism];
}

- (void) turnOffNaggingMechanism
{
    [self.naggingTimer invalidate];
    self.naggingTimer = nil;
}

- (void) setTimerForNaggingCheckup
{
    NSNumber *timeBeforeNagCheckup = self.user.settings.timeBetweenUserNags;
//    timeBeforeNagCheckup = [NSNumber numberWithFloat:20.];
    NSLog(@"[scheduler] Setting user-nagging timer for %@ seconds.",timeBeforeNagCheckup);
    if (self.naggingTimer)
    {
        [self.naggingTimer invalidate];
    }
    self.naggingTimer = [NSTimer scheduledTimerWithTimeInterval:[timeBeforeNagCheckup doubleValue]
                                                         target: self
                                                       selector: @selector(userNaggingCheckup)
                                                       userInfo: nil
                                                        repeats: YES];
   
}

- (void) userNaggingCheckup
{
    NSDate *now = [NSDate date];
    NSNumber *nowTimestamp = [NSNumber numberWithDouble:[now timeIntervalSince1970]];
    NSLog(@"[scheduler] time: %@. Checking if it's time to nag the user",now);

    if (![self.appDelegate isDataCollectionSupposedToBeOn])
    {
        NSLog(@"[scheduler] Data collection is off. Don't nag user and don't set timer for the next nag!");
        return;
    }

    // Look for latest user-corrected activity recently:
    NSNumber *recentPeriod = self.user.settings.recentTimePeriod;
    ES_Activity *latestVerifiedActivity = [ES_DataBaseAccessor getLatestCorrectedActivityWithinTheLatest:recentPeriod];
    
    NSString *question;
    NSMutableDictionary *userInfo;
    
    if (latestVerifiedActivity)
    {
        // Then ask user if they are still doing the same thing in the last x time:
        NSString *mainActivity = latestVerifiedActivity.userCorrection;
        NSSet *secondaryActivities = latestVerifiedActivity.secondaryActivities;
        NSString *mood = latestVerifiedActivity.mood;
        NSDate *latestVerifiedDate = [NSDate dateWithTimeIntervalSince1970:[latestVerifiedActivity.timestamp doubleValue]];
        NSTimeInterval timePassed = [now timeIntervalSinceDate:latestVerifiedDate];
        
        question = [NSString stringWithFormat:@"In the past %d minutes were you still %@",(int)timePassed/60,mainActivity];
        NSArray *secondaryActivitiesStrings = [ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[secondaryActivities allObjects]];
        if (secondaryActivities && [secondaryActivities count]>0)
        {
            NSString *secondaryString = [secondaryActivitiesStrings componentsJoinedByString:@","];
            question = [NSString stringWithFormat:@"%@ (%@)",question,secondaryString];
        }
        
        if (mood)
        {
            question = [NSString stringWithFormat:@"%@ and feeling %@",question,mood];
        }
        question = [NSString stringWithFormat:@"%@?",question];
    
        userInfo = [self.appDelegate constructUserInfoForNaggingWithCheckTime:nowTimestamp foundVerified:YES main:mainActivity secondary:secondaryActivitiesStrings mood:mood latestVerifiedTime:latestVerifiedActivity.timestamp];
    }
    else
    {
        // Then ask the user to provide feedback:
        question = @"Can you update what you're doing now?";
        userInfo = [self.appDelegate constructUserInfoForNaggingWithCheckTime:nowTimestamp foundVerified:NO main:nil secondary:nil mood:nil latestVerifiedTime:nil];
    }
    
    NSLog(@"[scheduler] Should ask question: [%@]",question);
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    // Set the timer for next time, before sending immediate notification:
    [self setTimerForNaggingCheckup];
    if (notification)
    {
        notification.fireDate = nil;
        notification.alertAction = @"ExtraSensory";
        notification.alertBody = question;
        notification.userInfo = userInfo;
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

- (void) activeFeedback: (ES_Activity *) activity
{
    NSLog( @"[scheduler] Start active feedback sample");
    
    [self.timer invalidate]; //turn off auto-sampling timer
    self.timer = nil;
    [self firstOpActive: activity];
    
    // turn auto-sampling timer back on
    self.timer = [NSTimer scheduledTimerWithTimeInterval: [self.user.settings.timeBetweenSampling doubleValue]
                                                      target: self
                                                selector: @selector(firstOp)
                                                    userInfo: nil
                                                     repeats: YES];
    
    if (![self.appDelegate getExampleActivityForPredeterminedLabels])
    {
        // There are no predetermined labels waiting, and:
        // The user just provided active feedback, so no need to nag them for a while. Set the nagging-timer starting now:
        [self setTimerForNaggingCheckup];
    }
}

-(void) firstOp
{
    ES_Activity *predeterminedLabels = [self.appDelegate getExampleActivityForPredeterminedLabels];
    if (predeterminedLabels)
    {
        // Create a new activity record with the predetermined labels:
        ES_Activity *newActivity = [ES_DataBaseAccessor newActivity];
        newActivity.userCorrection = predeterminedLabels.userCorrection;
        NSArray *userActivitiesStrings = [ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[predeterminedLabels.secondaryActivities allObjects]];
        [ES_DataBaseAccessor setSecondaryActivities:userActivitiesStrings forActivity:newActivity];
        newActivity.mood = predeterminedLabels.mood;
        
        NSLog(@"[scheduler] There are predetermined labels to attach to this new activity");
        [self.sensorManager setCurrentActivity:newActivity];
    }
    else
    {
        // Record with no given activity record:
        NSLog(@"[scheduler] There are no predetermined labels for now.");
        [self.sensorManager setCurrentActivity: nil];
    }
    NSLog(@"[scheduler] Record Sensors");
    [self.sensorManager record];
}

-(void) firstOpActive: (ES_Activity *) activity
{
    NSLog(@"[scheduler] Active feedback newly created activity was given.");
    
    NSLog(@"[scheduler] Record Sensors");
    [self.sensorManager setCurrentActivity: activity];
    [self.sensorManager record];
}


@end

