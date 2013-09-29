//
//  ES_SensorManager.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_SensorManager.h"
#import "ES_Sample.h"
#import "ES_DataBaseAccessor.h"


@interface ES_SensorManager()

@property NSTimer *timer;

@property NSNumber *counter;

@property NSArray *batchData;

@property (nonatomic) dispatch_queue_t sensorQueue;

@end

@implementation ES_SensorManager

@synthesize motionManager = _motionManager;

@synthesize locationManager = _locationManager;

@synthesize timer = _timer;

@synthesize counter = _counter;

@synthesize sampleFrequency = _sampleFrequency;

@synthesize sampleDuration = _sampleDuration;

@synthesize sensorQueue = _sensorQueue;

// Getter

- (dispatch_queue_t)sensorQueue
{
    if (!_sensorQueue)
    {
        return dispatch_queue_create( "ES_SensorQueue ", NULL );
    }
    return _sensorQueue;
    
}

- (CMMotionManager *)motionManager
{
    if (!_motionManager) _motionManager = [[CMMotionManager alloc] init];
    return _motionManager;
}

- (double) sampleFrequency
{
    if (!_sampleFrequency)
    {
        _sampleFrequency = 1;
    }
    return _sampleFrequency;
}

- (int) samplesPerBatch
{
    return (int)(self.sampleDuration * self.sampleFrequency);
}

- (double) sampleDuration
{
    if (!_sampleDuration)
    {
        _sampleDuration = 5.0;
    }
    return _sampleDuration;
}


- (void) record
{
    NSLog( @"record" );
    
    double interval = (1.0 / self.sampleFrequency);
    
    self.motionManager.accelerometerUpdateInterval = interval;
    self.motionManager.gyroUpdateInterval = interval;
    
    
    [self.locationManager startUpdatingLocation];
    [self.motionManager startAccelerometerUpdates];
    [self.motionManager startGyroUpdates];
    
    self.counter = 0;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval: interval
                                                  target: self
                                                selector: @selector(readSensors)
                                                userInfo: nil
                                                 repeats: YES];
}

- (void) readSensors
{
    NSLog( @"readSensors" );
    
    
    __block ES_Sample *s = [ES_DataBaseAccessor write];
    
    dispatch_async(self.sensorQueue, ^
                   {
                       NSLog( @"sp: %f",s.gps_speed = self.locationManager.location.speed);
                       NSLog( @"la: %f",s.gps_lat = self.locationManager.location.coordinate.latitude);
                       NSLog( @"lo: %f",s.gps_long = self.locationManager.location.coordinate.longitude);
                       NSLog( @"ax: %f",s.acc_x = self.motionManager.accelerometerData.acceleration.x);
                       NSLog( @"gx: %f",s.gyro_x = self.motionManager.gyroData.rotationRate.x);
                       NSLog( @"ay: %f",s.acc_y = self.motionManager.accelerometerData.acceleration.y);
                       NSLog( @"gy: %f",s.gyro_y = self.motionManager.gyroData.rotationRate.y);
                       NSLog( @"az: %f",s.acc_z = self.motionManager.accelerometerData.acceleration.z);
                       NSLog( @"gz: %f",s.gyro_z = self.motionManager.gyroData.rotationRate.z);
                       NSLog( @"at: %f",s.time = self.motionManager.accelerometerData.timestamp);
                       NSLog( @"gt: %f",s.time = self.motionManager.gyroData.timestamp);
                       
                       self.counter = [NSNumber numberWithInteger: [self.counter integerValue] + 1];
                       
                       if ([self.counter integerValue] >= self.samplesPerBatch )
                       {
                           [self.timer invalidate];
                           
                           self.counter = 0;
                           
                           [self.locationManager stopUpdatingLocation];
                           [self.motionManager stopAccelerometerUpdates];
                           [self.motionManager stopGyroUpdates];
                       }
                   });
}
- (void) stopRecording
{
    NSLog( @"stopRecording");
    
    [self.locationManager stopUpdatingLocation];
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopGyroUpdates];
}


@end
