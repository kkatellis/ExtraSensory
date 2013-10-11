//
//  ES_SensorManager.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_SensorManager.h"
#import "ES_DataBaseAccessor.h"
#import "ES_User.h"
#import "ES_AppDelegate.h"
#import "ES_Settings.h"
#import "ES_SensorSample.h"
#import "ES_Activity.h"

@interface ES_SensorManager()

@property NSTimer *timer;

@property NSNumber *counter;

@end

@implementation ES_SensorManager

@synthesize currentLocation = _currentLocation;

@synthesize motionManager = _motionManager;

@synthesize locationManager = _locationManager;

@synthesize timer = _timer;

@synthesize counter = _counter;

@synthesize sampleFrequency = _sampleFrequency;

@synthesize sampleDuration = _sampleDuration;

@synthesize isReady = _isReady;

@synthesize user = _user;

@synthesize currentActivity = _currentActivity;

- (ES_Activity *) currentActivity
{
    if (!_currentActivity)
    {
        _currentActivity = [ES_DataBaseAccessor newActivity];
    }
    return _currentActivity;
}

- (ES_User *) user
{
    if (!_user)
    {
        ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _user = appDelegate.user;
    }
    return _user;
}


- (NSNumber *) isReady
{
    if ( _isReady == nil )
    {
        _isReady = [NSNumber numberWithBool: YES];
    }
    return _isReady;
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
        _sampleFrequency = [self.user.settings.sampleRate doubleValue];
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
        _sampleDuration = [self.user.settings.sampleDuration doubleValue];
    }
    return _sampleDuration;
}


- (BOOL) record
{
    if (!self.isReady)
    {
        return NO;
    }
    
    //NSLog( @"record" );
    
    double interval = 1 / [self.user.settings.sampleRate doubleValue];
    NSLog(@"Sample interval = %f", interval);
    
    
    self.motionManager.accelerometerUpdateInterval = interval;
    self.motionManager.gyroUpdateInterval = interval;
    
    
    [self.locationManager setDelegate: self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager setDistanceFilter: kCLDistanceFilterNone];
    [self.locationManager setPausesLocationUpdatesAutomatically: NO];
    [self.locationManager startUpdatingLocation];
    
    
    NSLog( @"gpsAuth: %u", [CLLocationManager authorizationStatus]);
    
    
    
    [self.motionManager startDeviceMotionUpdates];
    [self.motionManager startAccelerometerUpdates];
    [self.motionManager startGyroUpdates];
    
    self.counter = 0;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval: interval
                                                  target: self
                                                selector: @selector(readSensorsIntoDictionary)
                                                userInfo: nil
                                                 repeats: YES];
    
    return YES;
}

- (void) readSensorsIntoDictionary
{
    
    ES_SensorSample *sample = [ES_DataBaseAccessor newSensorSample];
    
    sample.speed       = [NSNumber numberWithDouble: self.currentLocation.speed ];
    sample.lat         = [NSNumber numberWithDouble: self.currentLocation.coordinate.latitude ];
    sample.longitude   = [NSNumber numberWithDouble: self.currentLocation.coordinate.longitude ];
    
    sample.time        = [NSNumber numberWithDouble: self.motionManager.deviceMotion.timestamp ];
    
    
    sample.gyro_x      = [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.x ];
    sample.acc_x       = [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.x ];
    sample.gyro_y      = [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.y ];
    sample.acc_y       = [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.y ];
    sample.gyro_z      = [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.z ];
    sample.acc_z       = [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.z ];
    sample.mic_peak_db = [NSNumber numberWithDouble: 0.0 ];
    sample.mic_avg_db  = [NSNumber numberWithDouble: 0.0 ];
    
    
    [self.currentActivity addSensorSamplesObject: sample];
    
    self.counter = [NSNumber numberWithInteger: [self.counter integerValue] + 1];
    
    if ([self.counter integerValue] >= 800 )
    {
        self.currentActivity.timestamp = [NSNumber numberWithInt:(int)[[NSDate date] timeIntervalSince1970]];
        [self.timer invalidate];
        
        self.counter = 0;
        
        [self.locationManager stopUpdatingLocation];
        [self.motionManager stopAccelerometerUpdates];
        [self.motionManager stopGyroUpdates];
        
        
        [ES_DataBaseAccessor writeActivity: self.currentActivity];
        
        [self.user addActivitiesObject: self.currentActivity];
        
        self.currentActivity = [ES_DataBaseAccessor newActivity];
        
        self.isReady = [NSNumber numberWithBool: YES];
        
    }
}


#pragma mark Location Manager Delegate Methods

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog( @"status = %u", status);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.currentLocation = locations.lastObject;
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"[locationManager] ERROR: %@ DOMAIN: %@ CODE: %ld", [error localizedDescription], [error domain], (long)[error code]);
}


@end
