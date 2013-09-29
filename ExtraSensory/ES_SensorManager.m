//
//  ES_SensorManager.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_SensorManager.h"
#import "ES_AppDelegate.h"
#import "ES_Sample.h"
#import "ES_DataBaseAccessor.h"


@interface ES_SensorManager()

@property NSTimer *timer;

@property NSNumber *counter;

@property NSArray *batchData;

@end

@implementation ES_SensorManager

@synthesize motionManager = _motionManager;

@synthesize locationManager = _locationManager;

@synthesize acc_xyzt = _acc_xyzt;

@synthesize gyro_xyzt = _gyro_xyzt;

@synthesize timer = _timer;

@synthesize counter = _counter;

// Getter

- (CMMotionManager *)motionManager
{
    if (!_motionManager) _motionManager = [[CMMotionManager alloc] init];
    return _motionManager;
}

- (void) record
{
    NSLog( @"record" );
    
    self.motionManager.accelerometerUpdateInterval = .002;
    self.motionManager.gyroUpdateInterval = .002;

    
    [self.locationManager startUpdatingLocation];
    [self.motionManager startAccelerometerUpdates];
    [self.motionManager startGyroUpdates];
    
    self.counter = 0;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval: .002
                                                  target: self
                                                selector: @selector(readSensors)
                                                userInfo: nil
                                                 repeats: YES];
}

- (void) readSensors
{
    ES_Sample *s = [ES_DataBaseAccessor write];
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

    if ([self.counter integerValue] > 100)
    {
        self.counter = 0;
        [self.timer invalidate];
        [self.locationManager stopUpdatingLocation];
        [self.motionManager stopAccelerometerUpdates];
        [self.motionManager stopGyroUpdates];
    }
    
}

- (void) setUpdateIntervals: (double)frequency
{
    NSLog( @"setUpdateIntervals: %f", frequency);
    
}

- (void) stopRecording
{
    NSLog( @"stopRecording");
    
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopGyroUpdates];
    
    for (NSArray *a in self.acc_xyzt)
    {
        NSLog( @"from acc: %@, %@, %@, %@", [a objectAtIndex: 0], [a objectAtIndex: 1], [a objectAtIndex: 2], [a objectAtIndex: 3] );
    }
    for (NSArray *a in self.acc_xyzt)
    {
        NSLog( @"from gyro: %@, %@, %@, %@", [a objectAtIndex: 0], [a objectAtIndex: 1], [a objectAtIndex: 2], [a objectAtIndex: 3] );
    }
}


@end
