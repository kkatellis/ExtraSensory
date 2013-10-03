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

@interface ES_Scheduler()

@property (nonatomic, strong) ES_SensorManager *sensorManager;

@property (nonatomic, strong) ES_NetworkAccessor *networkAccessor;

@property int counter;

@property BOOL isReady;

@property double waitTime;

@property (nonatomic, strong) ES_HomeViewController *homeViewController;

@property (nonatomic, strong) NSMutableArray *predictions;

@end


@implementation ES_Scheduler

@synthesize sensorManager = _sensorManager;

@synthesize networkAccessor = _networkAccessor;

@synthesize counter = _counter;

@synthesize isReady = _isReady;

@synthesize waitTime = _waitTime;

@synthesize predictions = _predictions;

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
    

    NSTimer *timer;
    
    timer = [NSTimer new];
    
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
    
    
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 6.0
                                             target: self
                                           selector: @selector(operationCycler)
                                           userInfo: nil
                                            repeats: YES];    
}



- (void) operationCycler
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
}

-(void) firstOp
{
    NSLog(@"Record Sensors");
    
    [self.sensorManager record];
    
}

-(void) secondOp
{
    NSLog(@"Zip Data");

    [ES_DataBaseAccessor zipData];
    
}

-(void) thirdOp
{
    NSLog(@"upload");

    [self.networkAccessor upload];
    
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.homeViewController.logView.text = [appDelegate.predictions description];
}





@end

