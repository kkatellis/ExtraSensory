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


- (void) sampleSaveSendCycler: (ES_HomeViewController *) homeViewController
{
    self.homeViewController = homeViewController;
    
    NSLog( @"\n\nStart" );
    NSTimer *timer;
    timer = [NSTimer new];
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 50.0
                                             target: self
                                           selector: @selector(sampleSaveSend)
                                           userInfo: nil
                                            repeats: YES];
    

}


- (void) sampleSaveSend
{
        
    //////////////
    NSString *documentsDirectory = [ES_DataBaseAccessor applicationDocumentsDirectory];
    
    NSString *pathForLog = [documentsDirectory stringByAppendingPathComponent:@"NSLogRedirect.txt"];
    
    NSString *fileContents = [NSString stringWithContentsOfFile: pathForLog ];
    
    [self.homeViewController.logView setText: fileContents ];
    [self.homeViewController.logView scrollRangeToVisible:NSMakeRange([self.homeViewController.logView.text length], 0)];
    //////////////

    
    NSTimer *timer;
    
    timer = [NSTimer new];
    
    self.counter = 0;
    
    timer = [NSTimer scheduledTimerWithTimeInterval: self.waitTime
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
    self.predictions = self.networkAccessor.predictions;
    [self.homeViewController.logView setText: [self.predictions description]];
    
}





@end

