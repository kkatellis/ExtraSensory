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
#import "Reachability.h"
#import "ES_NetworkAccessor.h"

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
@synthesize callCenter = _callCenter;
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

#define MAG_X           @"magnet_x"
#define MAG_Y           @"magnet_y"
#define MAG_Z           @"magnet_z"

#define ALTITUDE        @"altitude"
#define FLOOR           @"floor"
#define HOR_ACCURACY    @"horizontal_accuracy"
#define VER_ACCURACY    @"vertical_accuracy"

#define WIFI_STATUS     @"wifi_status"
#define APP_STATE       @"app_state"
#define DEV_ORIENTATION @"device_orientation"
#define PROXIMITY       @"proximity"
#define ON_THE_PHONE    @"on_the_phone"

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
        _appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (ES_NetworkAccessor *) networkAccessor
{
    return [self appDelegate].networkAccessor;
}

- (CTCallCenter *) callCenter
{
    if (!_callCenter)
    {
        _callCenter = [CTCallCenter new];
    }
    return _callCenter;
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
    

        NSLog(@"[sensorManager] Turning on Dur sound Processor...");
        [self.soundProcessor startDurRecording];
    
    //--// Append our file name to the directory path
    HFFilePath = [[dataPath path] stringByAppendingPathComponent: fileName];
    
    // Remove any old data
    if( [[NSFileManager defaultManager] fileExistsAtPath:HFFilePath] ) {
        [[NSFileManager defaultManager] removeItemAtPath:HFFilePath error:nil];
        NSLog(@"[sensorManager] Removed any old sound file in directory.");
    }
}

- (BOOL) record
{
    // Setup HFData array
    if( HFDataBundle) {
        NSLog(@"[sensorManager] Clearing old HFDataBundle.");
        [HFDataBundle removeAllObjects];
    }
    else {
        HFDataBundle = [[NSMutableArray alloc] init];
    }
    [ES_DataBaseAccessor clearHFDataFile];
    [ES_DataBaseAccessor clearLabelFile];
    [ES_DataBaseAccessor clearSoundFile];
    
    // Mark begining recording:
    [self.appDelegate markRecordingRightNow];
    
    self.currentActivity.startTime = [NSDate date];
    self.currentActivity.timestamp = [NSNumber numberWithInt:(int)[self.currentActivity.startTime timeIntervalSince1970]];
    
    self.motionManager.accelerometerUpdateInterval = self.interval;
    self.motionManager.gyroUpdateInterval = self.interval;
    self.motionManager.magnetometerUpdateInterval = self.interval;
    
    [self.locationManager setDelegate: self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager setDistanceFilter: kCLDistanceFilterNone];
    [self.locationManager setPausesLocationUpdatesAutomatically: NO];
    [self.locationManager startUpdatingLocation];
    
    //NSLog( @"gpsAuth: %u", [CLLocationManager authorizationStatus]);
    
    [self.motionManager startDeviceMotionUpdates];
    [self.motionManager startAccelerometerUpdates];
    [self.motionManager startGyroUpdates];
    [self.motionManager startMagnetometerUpdates];
    
    [self.soundProcessor startDurRecording];
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval: self.interval
                                                  target: self
                                                selector: @selector(packHFData)
                                                userInfo: nil
                                                 repeats: YES];
    
    return YES;
}


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
    [self.motionManager stopMagnetometerUpdates];
    [self.soundProcessor pauseDurRecording];
    [self.appDelegate markNotRecordingRightNow];
}

- (NSMutableDictionary *) addDeviceIndicatorsAndLowFreqMeasurements:(NSMutableDictionary *)HFDataList
{
    // Discrete indicators:
    [HFDataList setValue:[NSNumber numberWithInt:[[self networkAccessor] reachabilityStatus]] forKey:[NSString stringWithFormat:@"lf_%@",WIFI_STATUS]];
    [HFDataList setValue:[NSNumber numberWithInteger:[UIApplication sharedApplication].applicationState] forKey:[NSString stringWithFormat:@"lf_%@",APP_STATE]];
    [HFDataList setValue:[NSNumber numberWithInt:[[UIDevice currentDevice] orientation]] forKey:[NSString stringWithFormat:@"lf_%@",DEV_ORIENTATION]];
    [HFDataList setValue:[NSNumber numberWithBool:[[UIDevice currentDevice] proximityState]] forKey:[NSString stringWithFormat:@"lf_%@",PROXIMITY]];
    BOOL onThePhone = ((self.callCenter.currentCalls) && ([self.callCenter.currentCalls count] > 0));
    [HFDataList setValue:[NSNumber numberWithBool:onThePhone] forKey:[NSString stringWithFormat:@"lf_%@",ON_THE_PHONE]];
    
    // Scalar measurements:
    [HFDataList setValue:[NSNumber numberWithDouble:self.currentLocation.altitude] forKey:[NSString stringWithFormat:@"lf_%@",ALTITUDE]];
    [HFDataList setValue:[NSNumber numberWithInteger:self.currentLocation.floor.level] forKey:[NSString stringWithFormat:@"lf_%@",FLOOR]];
    [HFDataList setValue:[NSNumber numberWithDouble:self.currentLocation.horizontalAccuracy] forKey:[NSString stringWithFormat:@"lf_%@",HOR_ACCURACY]];
    [HFDataList setValue:[NSNumber numberWithDouble:self.currentLocation.verticalAccuracy] forKey:[NSString stringWithFormat:@"lf_%@",VER_ACCURACY]];
    
    return HFDataList;
}

-(void) packHFData
{
    //--// Pack most recent data and place it within Data Bundle
    if( [HFDataBundle count] % 100 == 0 ) {
        NSLog( @"[sensorManager] Collected %lu HF samples", (unsigned long)[HFDataBundle count]);
    }
    if ([HFDataBundle count] == self.samplesPerBatch )
    {
        [self.timer invalidate];
        self.timer = nil;
        
        [self.locationManager stopUpdatingLocation];
        [self.motionManager stopAccelerometerUpdates];
        [self.motionManager stopGyroUpdates];
        [self.motionManager stopMagnetometerUpdates];
        
        //added MFCC extraction here
        [self.soundProcessor processMFCC];
        
        [ES_DataBaseAccessor writeData: HFDataBundle];
        [ES_DataBaseAccessor writeActivity: self.currentActivity];
        
        // Mark finished recording:
        [self.appDelegate markNotRecordingRightNow];
    }
    
    
    NSMutableDictionary *HFDataList = [[NSMutableDictionary alloc] initWithCapacity:13];
    
    [HFDataList setObject: [NSNumber numberWithDouble: self.currentLocation.speed ] forKey: SPEED];
    [HFDataList setObject: [NSNumber numberWithDouble: self.currentLocation.coordinate.latitude ] forKey: LAT];
    [HFDataList setObject: [NSNumber numberWithDouble: self.currentLocation.coordinate.longitude ] forKey: LNG];
    
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.timestamp ] forKey: TIMESTAMP];
    
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.x ] forKey: GYR_X];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.x ] forKey: ACC_X];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.magnetometerData.magneticField.x] forKey:MAG_X];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.y ] forKey: GYR_Y];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.y ] forKey: ACC_Y];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.magnetometerData.magneticField.y] forKey:MAG_Y];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.rotationRate.z ] forKey: GYR_Z];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.deviceMotion.userAcceleration.z ] forKey: ACC_Z];
    [HFDataList setObject: [NSNumber numberWithDouble: self.motionManager.magnetometerData.magneticField.z] forKey:MAG_Z];
    
    if( [HFDataBundle count] % 100 == 0 ) {
        HFDataList = [self addDeviceIndicatorsAndLowFreqMeasurements:HFDataList];
    }
    
    [HFDataBundle addObject:HFDataList];
    
}



#pragma mark Location Manager Delegate Methods

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog( @"[sensorManager]:[locationManager] status = %u", status);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.currentLocation = locations.lastObject;
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"[sensorManager]:[locationManager] ERROR: %@ DOMAIN: %@ CODE: %ld", [error localizedDescription], [error domain], (long)[error code]);
}


@end
