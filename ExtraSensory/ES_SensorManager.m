//
//  ES_SensorManager.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//
//

#import "ES_SensorManager.h"
#import "ES_DataBaseAccessor.h"
#import "ES_User.h"
#import "ES_AppDelegate.h"
#import "ES_Settings.h"
#import "ES_Activity.h"
#import "ES_SoundWaveProcessor.h"

// In Hertz
#define HF_SAMPLING_RATE    40

#define HF_PRE_FNAME        @"HF_PRE_DATA.txt"
#define HF_DUR_FNAME        @"HF_DUR_DATA.txt"

@interface ES_SensorManager()

@property NSTimer *timer;
@property NSTimer *soundTimer;
@property NSNumber *counter;

@property (nonatomic, strong)  ES_AppDelegate *appDelegate;

@end

@implementation ES_SensorManager

@synthesize soundProcessor = _soundProcessor;
@synthesize currentLocation = _currentLocation;
@synthesize motionManager = _motionManager;
@synthesize locationManager = _locationManager;
@synthesize timer = _timer;
@synthesize soundTimer = _soundTimer;
@synthesize counter = _counter;
@synthesize sampleFrequency = _sampleFrequency;
@synthesize interval = _interval;
@synthesize sampleDuration = _sampleDuration;
@synthesize isReady = _isReady;
@synthesize user = _user;
@synthesize currentActivity = _currentActivity;

//--// API data keys
#define LAT             @"lat"
#define LNG             @"long"
#define SPEED           @"speed"
#define TIMESTAMP       @"timestamp"

#define ACC_X           @"acc_x"
#define ACC_Y           @"acc_y"
#define ACC_Z           @"acc_z"

#define GYR_X           @"gyro_x"
#define GYR_Y           @"gyro_y"
#define GYR_Z           @"gyro_z"

-(ES_SoundWaveProcessor *) soundProcessor
{
    if(!_soundProcessor)
    {
        _soundProcessor = [[ES_SoundWaveProcessor alloc] init];
    }
    return _soundProcessor;
}

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
        _user = self.appDelegate.user;
    }
    return _user;
}

- (ES_AppDelegate *) appDelegate
{
    if (!_appDelegate)
    {
        _appDelegate = [[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
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

- (double) interval
{
    if (!_interval)
    {
        _interval = 1 / [self.user.settings.sampleRate doubleValue];
    }
    return _interval;
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

/* starts recording of microphone depending on filename*/
- (void) _prepStage: (NSString *)fileName {
    
    //--// Get user documents folder path
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *dataPath = [fileManager URLForDirectory: NSDocumentDirectory
                                          inDomain: NSUserDomainMask
                                 appropriateForURL: nil
                                            create: YES
                                             error: nil];
    

        NSLog(@"Turning on Dur sound Processor...");
        [self.soundProcessor startDurRecording];
    
    //--// Append our file name to the directory path
    HFFilePath = [[dataPath path] stringByAppendingPathComponent: fileName];
    
    // Remove any old data
    if( [[NSFileManager defaultManager] fileExistsAtPath:HFFilePath] ) {
        [[NSFileManager defaultManager] removeItemAtPath:HFFilePath error:nil];
        NSLog(@"removed any old sound file in direc");
    }
}

- (BOOL) record
{
    //[ES_DataBaseAccessor getMostRecentActivity];
    
    // Setup HFData array
    if( HFDataBundle) {
        NSLog(@"clearing old HFDataBundle");
        [HFDataBundle removeAllObjects];
    }
    else {
        HFDataBundle = [[NSMutableArray alloc] init];
    }
    [ES_DataBaseAccessor clearHFDataFile];
    [ES_DataBaseAccessor clearLabelFile];
    
    self.currentActivity.timestamp = [NSNumber numberWithInt:(int)[[NSDate date] timeIntervalSince1970]];
    
    self.motionManager.accelerometerUpdateInterval = self.interval;
    self.motionManager.gyroUpdateInterval = self.interval;
    
    [self.locationManager setDelegate: self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager setDistanceFilter: kCLDistanceFilterNone];
    [self.locationManager setPausesLocationUpdatesAutomatically: NO];
    [self.locationManager startUpdatingLocation];
    
    //NSLog( @"gpsAuth: %u", [CLLocationManager authorizationStatus]);
    
    [self.motionManager startDeviceMotionUpdates];
    [self.motionManager startAccelerometerUpdates];
    [self.motionManager startGyroUpdates];
    
    [self.soundProcessor startDurRecording];
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval: self.interval
                                                  target: self
                                                selector: @selector(packHFData)
                                                userInfo: nil
                                                 repeats: YES];
    
    return YES;
}

//- (void) readSensorsIntoDictionary
//{
//    // using the new function packHFData
//    ES_SensorSample *sample = [ES_DataBaseAccessor newSensorSample];
//    
//    sample.speed       = [NSNumber numberWithDouble: self.currentLocation.speed ];
//    sample.lat         = [NSNumber numberWithDouble: self.currentLocation.coordinate.latitude ];
//    sample.longitude   = [NSNumber numberWithDouble: self.currentLocation.coordinate.longitude ];
//    
//    sample.time        = [NSNumber numberWithDouble: self.motionManager.deviceMotion.timestamp ];
//    
//    
//    sample.gyro_x      = [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.x ];
//    sample.acc_x       = [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.x ];
//    sample.gyro_y      = [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.y ];
//    sample.acc_y       = [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.y ];
//    sample.gyro_z      = [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.z ];
//    sample.acc_z       = [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.z ];
//    
//    // add samples for avg and peak db
//    
//    
//    [self.currentActivity addSensorSamplesObject: sample];
//    
//    self.counter = [NSNumber numberWithInteger: [self.counter integerValue] + 1];
//    
//    if ([self.counter integerValue] >= 800 )
//    {
//        self.currentActivity.timestamp = [NSNumber numberWithInt:(int)[[NSDate date] timeIntervalSince1970]];
//        [self.timer invalidate];
//        
//        self.counter = 0;
//        
//        [self.locationManager stopUpdatingLocation];
//        [self.motionManager stopAccelerometerUpdates];
//        [self.motionManager stopGyroUpdates];
//       // [self.soundProcessor pauseDurRecording];
//       // stop recording sound
//        
//        [ES_DataBaseAccessor writeActivity: self.currentActivity];
//        
//        [self.user addActivitiesObject: self.currentActivity];
//        
//        self.currentActivity = [ES_DataBaseAccessor newActivity];
//        self.isReady = [NSNumber numberWithBool: YES];
//        
//    }
//}

-(void) turnOffRecording
{
    NSLog(@"[sensorManager] turnOffRecording");
    if (!self.appDelegate.currentlyUploading)
    {
        if (self.currentActivity)
        {
            // delete a partially created activity
            [ES_DataBaseAccessor deleteActivity:self.currentActivity];
            [self setCurrentActivity: nil];
        }
    }
    [self.timer invalidate];
    self.timer = nil;
    [self.locationManager stopUpdatingLocation];
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopGyroUpdates];
    [self.soundProcessor pauseDurRecording];
}

-(void) packHFData
{
    //--// Pack most recent data and place it within Data Bundle
    if( [HFDataBundle count] % 100 == 0 ) {
        NSLog( @"Collected %lu HF samples", (unsigned long)[HFDataBundle count]);
    }
    if ([HFDataBundle count] == self.samplesPerBatch )
    {
        [self.timer invalidate];
        self.timer = nil;
        NSLog(@"invalidated timer %@", self.timer);
        
        [self.locationManager stopUpdatingLocation];
        [self.motionManager stopAccelerometerUpdates];
        [self.motionManager stopGyroUpdates];
        
        [ES_DataBaseAccessor writeData: HFDataBundle];
        [ES_DataBaseAccessor writeActivity: self.currentActivity];
    }
    
    NSMutableDictionary *HFDataList = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    [HFDataList setObject: [NSNumber numberWithDouble: self.currentLocation.speed ] forKey: SPEED];
    [HFDataList setObject: [NSNumber numberWithDouble: self.currentLocation.coordinate.latitude ] forKey: LAT];
    [HFDataList setObject: [NSNumber numberWithDouble: self.currentLocation.coordinate.longitude ] forKey: LNG];
    
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.timestamp ] forKey: TIMESTAMP];
    
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.x ] forKey: GYR_X];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.x ] forKey: ACC_X];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.y ] forKey: GYR_Y];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.y ] forKey: ACC_Y];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.z ] forKey: GYR_Z];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.z ] forKey: ACC_Z];
    
    [HFDataBundle addObject:HFDataList];
    
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
