//
//  ES_AccelerometerAccessor.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_AccelerometerAccessor.h"
#import "AccelerometerData.h"
#import "Samples.h"
#import "ES_SensorManager.h"
#import "ES_AppDelegate.h"
#import "ES_DataBaseAccessor.h"

// Private interface
@interface ES_AccelerometerAccessor()

@property (strong, nonatomic) NSString *batchID;

@property NSTimer *timer;

@end


@implementation ES_AccelerometerAccessor

@synthesize motionManager = _motionManager;
@synthesize frequency = _frequency;
@synthesize timer = _timer;
@synthesize recordDuration = _recordDuration;

-(NSTimeInterval)recordDuration
{
    if (!_recordDuration)
        _recordDuration = 5.0;
    return _recordDuration;
}

-(NSNumber *)frequency
{
    if (!_frequency) _frequency = [NSNumber numberWithDouble: .05];
    return _frequency;
}

-(void)record
{
    self.motionManager.accelerometerUpdateInterval = [self.frequency doubleValue];
    
    NSString * timeMarker1;
    NSString * timeMarker2;
    
    ES_AccelerometerAccessor * __weak weakSelf = self;
    if ([weakSelf.motionManager isAccelerometerAvailable])
    {
        timeMarker1 = [NSString stringWithFormat: @"%f",[[NSDate date] timeIntervalSince1970]];
        weakSelf.batchID = [[[(ES_AppDelegate *)[[UIApplication sharedApplication] delegate] uuid] UUIDString] stringByAppendingString:timeMarker1];
        
        if (![weakSelf.motionManager isAccelerometerActive])
        {
            NSLog(@"start accelerometer updates @ %@", timeMarker1);
            NSLog(@"timeWindow : %f", self.recordDuration);
            
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.recordDuration
                                                          target:self
                                                        selector:@selector(stopRecordingAccelerometer)
                                                        userInfo:nil
                                                         repeats:NO];
            
            [weakSelf.motionManager startAccelerometerUpdatesToQueue: [NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accData, NSError *error){
                
                Samples *s;
                s = (Samples *)[ES_DataBaseAccessor write: @"Samples"];
                AccelerometerData *a;
                a = (AccelerometerData *)[ES_DataBaseAccessor write: @"AccelerometerData"];
                
                s.accelerometerData = a;
                a.samples = s;
                s.accelerometerData.x = [NSNumber numberWithDouble: accData.acceleration.x];
                s.accelerometerData.y = [NSNumber numberWithDouble: accData.acceleration.y];
                s.accelerometerData.z = [NSNumber numberWithDouble: accData.acceleration.z];
                s.accelerometerData.time = [NSNumber numberWithDouble: accData.timestamp];
                
                s.batchID = [self.batchID copy];
                                
            }];
        }
        timeMarker2 = [NSString stringWithFormat: @"%f",[[NSDate date] timeIntervalSince1970]];
    }
    
    [ES_DataBaseAccessor save];
}



-(void)stopRecordingAccelerometer
{
    if (self.motionManager.isAccelerometerActive)
    {
        [self.motionManager stopAccelerometerUpdates];
        NSLog(@"stop accelerometer updates");
    }
    else
        NSLog(@"Accelerometer isn't running!");
}






@end
