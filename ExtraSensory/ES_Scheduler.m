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

@interface ES_Scheduler()

@property (nonatomic, strong) ES_SensorManager *sensorManager;

@property (nonatomic, strong) ES_NetworkAccessor *networkAccessor;

@property int counter;

@property BOOL isReady;

@property double waitTime;

@end


@implementation ES_Scheduler

@synthesize sensorManager = _sensorManager;

@synthesize networkAccessor = _networkAccessor;

@synthesize counter = _counter;

@synthesize isReady = _isReady;

@synthesize waitTime = _waitTime;

- (double) waitTime
{
    if (!_waitTime)
    {
        _waitTime = 2.0;
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


- (void) sampleSaveSendCycler
{
    NSLog( @"Start" );
    NSTimer *timer;
    timer = [NSTimer new];
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 10.0
                                             target: self
                                           selector: @selector(sampleSaveSend)
                                           userInfo: nil
                                            repeats: YES];
}


- (void) sampleSaveSend
{
        
    
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
    NSLog(@"firstOp");
    
    [self.sensorManager record];
    
}

-(void) secondOp
{
    NSLog(@"secondOp");

    [ES_DataBaseAccessor zipData];
    
}

-(void) thirdOp
{
    NSLog(@"thirdOp");

    [self.networkAccessor upload];
}





@end

