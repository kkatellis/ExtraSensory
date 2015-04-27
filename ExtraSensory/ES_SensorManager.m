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
//#import "ES_ImageProcessor.h"

// In Hertz
#define HF_SAMPLING_RATE    40

#define HF_PRE_FNAME        @"HF_PRE_DATA.txt"
#define HF_DUR_FNAME        @"HF_DUR_DATA.txt"

//--// API data keys


//#################
// New sampling method fields:

#define RAW_ACC_X           @"raw_acc_x"
#define RAW_ACC_Y           @"raw_acc_y"
#define RAW_ACC_Z           @"raw_acc_z"
#define RAW_ACC_TIME        @"raw_acc_timeref"

#define RAW_GYR_X           @"raw_gyro_x"
#define RAW_GYR_Y           @"raw_gyro_y"
#define RAW_GYR_Z           @"raw_gyro_z"
#define RAW_GYR_TIME        @"raw_gyro_timeref"

#define RAW_MAG_X           @"raw_magnet_x"
#define RAW_MAG_Y           @"raw_magnet_y"
#define RAW_MAG_Z           @"raw_magnet_z"
#define RAW_MAG_TIME        @"raw_magnet_timeref"

// measurements processed by CMDeviceMotionManager:
#define PROC_USER_ACC_X     @"processed_user_acc_x"
#define PROC_USER_ACC_Y     @"processed_user_acc_y"
#define PROC_USER_ACC_Z     @"processed_user_acc_z"

#define PROC_GRAV_X         @"processed_gravity_x"
#define PROC_GRAV_Y         @"processed_gravity_y"
#define PROC_GRAV_Z         @"processed_gravity_z"

#define PROC_GYR_X          @"processed_gyro_x"
#define PROC_GYR_Y          @"processed_gyro_y"
#define PROC_GYR_Z          @"processed_gyro_z"

#define PROC_ROLL           @"processed_roll"
#define PROC_PITCH          @"processed_pitch"
#define PROC_YAW            @"processed_yaw"

#define PROC_MAG_X          @"processed_magnet_x"
#define PROC_MAG_Y          @"processed_magnet_y"
#define PROC_MAG_Z          @"processed_magnet_z"

#define PROC_TIME           @"processed_timeref"

// Location:
#define LOC_LAT             @"location_latitude"
#define LOC_LONG            @"location_longitude"
#define LOC_ALT             @"location_altitude"
#define LOC_FLOOR           @"location_floor"
#define LOC_SPEED           @"location_speed"

#define LOC_HOR_ACCURACY    @"location_horizontal_accuracy"
#define LOC_VER_ACCURACY    @"location_vertical_accuracy"

#define LOC_TIME            @"location_timestamp"

#define LOW_FREQ            @"low_frequency"

//############
// low frequency measurements:

#define ALTITUDE        @"altitude"
#define FLOOR           @"floor"
#define HOR_ACCURACY    @"horizontal_accuracy"
#define VER_ACCURACY    @"vertical_accuracy"

#define WIFI_STATUS     @"wifi_status"
#define APP_STATE       @"app_state"
#define DEV_ORIENTATION @"device_orientation"
#define PROXIMITY       @"proximity"
#define ON_THE_PHONE    @"on_the_phone"
#define BATTERY_LEVEL   @"battery_level"
#define BATTERY_STATE   @"battery_state"

#define SCREEN_BRIGHT   @"screen_brightness"
#define CAMERA          @"camera"

@interface ES_SensorManager()

@property NSTimer *timer;
@property NSTimer *soundTimer;
@property NSNumber *counter;

@property (nonatomic, strong)  ES_AppDelegate *appDelegate;

@property (nonatomic, strong) NSMutableDictionary *hfData;
@property (nonatomic) BOOL usingTimerForSampling;

//@property (nonatomic, strong) ES_ImageProcessor *cameraProcessor;

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
@synthesize usingTimerForSampling = _usingTimerForSampling;
//@synthesize cameraProcessor = _cameraProcessor;



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
        _interval = 1. / [self.user.settings.sampleRate doubleValue];
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

- (BOOL) usingTimerForSampling
{
    _usingTimerForSampling = NO;
    return _usingTimerForSampling;
}

//- (ES_ImageProcessor *)cameraProcessor {
//    if (!_cameraProcessor) {
//        _cameraProcessor = [ES_ImageProcessor new];
//    }
//    return _cameraProcessor;
//}
//


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
    [self recordWithoutNSTimer];
    
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
    [self.motionManager stopDeviceMotionUpdates];
    [self.soundProcessor pauseDurRecording];
    //[self.cameraProcessor stopSession];
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


// #############################################################
// New version of recording measurements (not relying on NSTimer, which is no accurate, especially, when app goes to background):

- (void) recordWithoutNSTimer
{
    // Prepare for collection of new measurements:
    if (self.hfData)
    {
        NSLog(@"[sensorManager] Clearing old HF data.");
        [self.hfData removeAllObjects];
    }
    else
    {
        self.hfData = [NSMutableDictionary dictionaryWithCapacity:20];
    }
    [ES_DataBaseAccessor clearHFDataFile];
    [ES_DataBaseAccessor clearLabelFile];
    [ES_DataBaseAccessor clearSoundFile];
    
    // Mark begining recording:
    [self.appDelegate markRecordingRightNow];
    
    self.currentActivity.startTime = [NSDate date];
    self.currentActivity.timestamp = [NSNumber numberWithInt:(int)[self.currentActivity.startTime timeIntervalSince1970]];
    
    // Prepare sensing devices:
    self.motionManager.accelerometerUpdateInterval = self.interval;
    self.motionManager.gyroUpdateInterval = self.interval;
    self.motionManager.magnetometerUpdateInterval = self.interval;
    self.motionManager.deviceMotionUpdateInterval = self.interval;
    
    [self.locationManager setDelegate: self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager setDistanceFilter: kCLDistanceFilterNone];
    [self.locationManager setPausesLocationUpdatesAutomatically: NO];
    
    // Start the sampling:
    NSLog(@"[sensorManager] Starting sampling sensors...(%@)",[NSDate date]);
    
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    /// Notice: when used a new queue (or separate new queue for each sensor) there were bugs after finished sampling (red dot took time to disappear and network connection failed to get response)
    
    [self.soundProcessor startDurRecording];
    // ADD WATCHRECORDING HERE
    
    if (self.motionManager.accelerometerAvailable)
    {
        [self.motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error ) {
            if (error)
            {
                NSLog(@"caught error: %@",error);
            }
            [self addAccelerationSample:accelerometerData];
        }];
    }
    
    if (self.motionManager.gyroAvailable)
    {
        [self.motionManager startGyroUpdatesToQueue:queue withHandler:^(CMGyroData *gyroscopeData, NSError *error) {
            if (error)
            {
                NSLog(@"caught error: %@",error);
            }
            [self addGyroscopeSample:gyroscopeData];
        }];
    }
    
    if (self.motionManager.magnetometerAvailable)
    {
        [self.motionManager startMagnetometerUpdatesToQueue:queue withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
            if (error)
            {
                NSLog(@"caught error: %@",error);
            }
            [self addMagnetometerSample:magnetometerData];
        }];
    }
    
    if (self.motionManager.deviceMotionAvailable)
    {
        [self.motionManager startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            if (error)
            {
                NSLog(@"caught error: %@",error);
            }
            [self addDeviceMotionSample:deviceMotion];
        }];
    }
    
    if ([CLLocationManager locationServicesEnabled])
    {
        // Stop updating before start updating, to force getting an update:
        [self.locationManager stopUpdatingLocation];
        [self.locationManager startUpdatingLocation];
    }
    
//    // Data from cameras:
//    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) {
//        [[self cameraProcessor] startCameraCycle];
//    }
//    else {
//        NSLog(@"[sensorManager] Not authorized to use camera");
//    }

    // Add low frequency (one time) measurements:
    [self addDeviceIndicatorsToDataBundle];
    
    
}

- (void) addToHighFrequencyDataNumericValue:(NSNumber *)value forField:(NSString *)field
{
    if (![self.hfData valueForKey:field])
    {
        // Create this field for the first time, as an array:
        [self.hfData setValue:[NSMutableArray arrayWithCapacity:[self samplesPerBatch]] forKey:field];
    }
    // Add the numeric value to the array:
    [[self.hfData valueForKey:field] addObject:value];
}

- (void) addDeviceMotionSample:(CMDeviceMotion *)deviceMotionData
{
    // Are we already done collecting:
    NSUInteger curr_count = [self countField:PROC_GRAV_X];
    if (curr_count >= [self samplesPerBatch])
    {
        NSLog(@"[sensorManager] Got new deviceMotion sample, but don't need it, sice we already have enough samples collected: %lu.",(unsigned long)curr_count);
        return;
    }
    
    // Add the newly received measurements:
    // Acceleration:
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.gravity.x] forField:PROC_GRAV_X];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.gravity.y] forField:PROC_GRAV_Y];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.gravity.z] forField:PROC_GRAV_Z];
    
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.userAcceleration.x] forField:PROC_USER_ACC_X];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.userAcceleration.y] forField:PROC_USER_ACC_Y];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.userAcceleration.z] forField:PROC_USER_ACC_Z];
    
    // Rotation rate (gyro):
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.rotationRate.x] forField:PROC_GYR_X];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.rotationRate.y] forField:PROC_GYR_Y];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.rotationRate.z] forField:PROC_GYR_Z];

    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.attitude.roll] forField:PROC_ROLL];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.attitude.pitch] forField:PROC_PITCH];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.attitude.yaw] forField:PROC_YAW];
    
    // magnet:
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.magneticField.field.x] forField:PROC_MAG_X];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.magneticField.field.y] forField:PROC_MAG_Y];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.magneticField.field.z] forField:PROC_MAG_Z];

    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:deviceMotionData.timestamp] forField:PROC_TIME];
    
    // Check how many samples have already been collected in this bundle:
    curr_count = [self countField:PROC_GRAV_X];
//    if (curr_count % 100 == 0)
//    {
//        NSLog(@"[sensorManager] Collected %lu HF device motion samples (%@).",(unsigned long)curr_count,[NSDate date]);
//    }
    if (curr_count >= [self samplesPerBatch])
    {
        //NSLog(@"[sensorManager] Have enough device motion samples. Stopping device motion (%@)",[NSDate date]);
        [self.motionManager stopDeviceMotionUpdates];
        [self checkIfDataBundleReadyAndHandleIt];
    }
}

- (void) addMagnetometerSample:(CMMagnetometerData *)magnetData
{
    // Are we already done collecting:
    NSUInteger curr_count = [self countField:RAW_MAG_X];
    if (curr_count >= [self samplesPerBatch])
    {
        NSLog(@"[sensorManager] Got new magnetometer sample, but don't need it, since we already have enough samples collected: %lu.",(unsigned long)curr_count);
        return;
    }
    
    // Add the newly received measurements:
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:magnetData.magneticField.x] forField:RAW_MAG_X];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:magnetData.magneticField.y] forField:RAW_MAG_Y];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:magnetData.magneticField.z] forField:RAW_MAG_Z];
    
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:magnetData.timestamp] forField:RAW_MAG_TIME];
    
    // Check how many samples have already been collected in this bundle:
    curr_count = [self countField:RAW_MAG_X];
//    if (curr_count % 100 == 0)
//    {
//        NSLog(@"[sensorManager] Collected %lu HF magnet samples (%@).",(unsigned long)curr_count,[NSDate date]);
//    }
    if (curr_count >= [self samplesPerBatch])
    {
        //NSLog(@"[sensorManager] Have enough magnet samples. Stopping magnetometer (%@)",[NSDate date]);
        [self.motionManager stopMagnetometerUpdates];
        [self checkIfDataBundleReadyAndHandleIt];
    }
}

- (void) addGyroscopeSample:(CMGyroData *)gyroData
{
    // Are we already done collecting:
    NSUInteger curr_count = [self countField:RAW_GYR_X];
    if (curr_count >= [self samplesPerBatch])
    {
        NSLog(@"[sensorManager] Got new gyroscope sample, but don't need it, since we already have enough samples collected: %lu.",(unsigned long)curr_count);
        return;
    }
    
    // Add the newly received measurements:
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:gyroData.rotationRate.x] forField:RAW_GYR_X];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:gyroData.rotationRate.y] forField:RAW_GYR_Y];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:gyroData.rotationRate.z] forField:RAW_GYR_Z];
    
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:gyroData.timestamp] forField:RAW_GYR_TIME];
    
    // Check how many samples have already been collected in this bundle:
    curr_count = [self countField:RAW_GYR_X];
//    if (curr_count % 100 == 0)
//    {
//        NSLog(@"[sensorManager] Collected %lu HF gyro samples (%@).",(unsigned long)curr_count,[NSDate date]);
//    }
    if (curr_count >= [self samplesPerBatch])
    {
        //NSLog(@"[sensorManager] Have enough gyroscope samples. Stopping gyroscope (%@)",[NSDate date]);
        [self.motionManager stopGyroUpdates];
        [self checkIfDataBundleReadyAndHandleIt];
    }
}

- (void) addAccelerationSample:(CMAccelerometerData *)accelerometerData
{
    // Are we already done collecting:
    unsigned long curr_count = [self countField:RAW_ACC_X];
    if (curr_count >= [self samplesPerBatch])
    {
        NSLog(@"[sensorManager] Got new acceleration sample, but don't need it, since we already have enough samples collected: %lu.",(unsigned long)curr_count);
        return;
    }
    
    // Add the newly received measurements:
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:accelerometerData.acceleration.x] forField:RAW_ACC_X];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:accelerometerData.acceleration.y] forField:RAW_ACC_Y];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:accelerometerData.acceleration.z] forField:RAW_ACC_Z];

    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:accelerometerData.timestamp] forField:RAW_ACC_TIME];
    
    // Check how many samples have already been collected in this bundle:
    curr_count = [self countField:RAW_ACC_X];
    if (curr_count % 100 == 0)
    {
        NSLog(@"[sensorManager] Collected: %lu acc, %lu gyro, %lu magnet, %lu motion (%f).",curr_count,[self countField:RAW_GYR_X],[self countField:RAW_MAG_X],[self countField:PROC_GRAV_X],[[NSDate date] timeIntervalSince1970]);
    }
    if (curr_count >= [self samplesPerBatch])
    {
        NSLog(@"[sensorManager] Have enough acceleration samples. Stopping accelerometer. (%@)",[NSDate date]);
        [self.motionManager stopAccelerometerUpdates];
        [self checkIfDataBundleReadyAndHandleIt];
    }
}

- (void) addLocationSample:(CLLocation *)location
{
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:location.coordinate.latitude] forField:LOC_LAT];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:location.coordinate.longitude] forField:LOC_LONG];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:location.altitude] forField:LOC_ALT];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:location.speed] forField:LOC_SPEED];
    
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:location.horizontalAccuracy] forField:LOC_HOR_ACCURACY];
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:location.verticalAccuracy] forField:LOC_VER_ACCURACY];
    //[self addToHighFrequencyDataNumericValue:[NSNumber numberWithInteger:location.floor.level] forField:LOC_FLOOR];
    
    [self addToHighFrequencyDataNumericValue:[NSNumber numberWithDouble:[location.timestamp timeIntervalSince1970]] forField:LOC_TIME];
}

- (void) addDeviceIndicatorsToDataBundle
{
    NSMutableDictionary *lfData = [NSMutableDictionary dictionaryWithCapacity:6];
    // Discrete indicators:
    [lfData setValue:[NSNumber numberWithInt:[[self networkAccessor] reachabilityStatus]] forKey:WIFI_STATUS];
    [lfData setValue:[NSNumber numberWithInteger:[UIApplication sharedApplication].applicationState] forKey:APP_STATE];
    [lfData setValue:[NSNumber numberWithInt:[[UIDevice currentDevice] orientation]] forKey:DEV_ORIENTATION];
    
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    [lfData setValue:[NSNumber numberWithBool:[[UIDevice currentDevice] proximityState]] forKey:PROXIMITY];
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [lfData setValue:[NSNumber numberWithFloat:[[UIDevice currentDevice] batteryLevel]] forKey:BATTERY_LEVEL];
    [lfData setValue:[NSNumber numberWithInt:[[UIDevice currentDevice] batteryState]] forKey:BATTERY_STATE];
    
    BOOL onThePhone = ((self.callCenter.currentCalls) && ([self.callCenter.currentCalls count] > 0));
    [lfData setValue:[NSNumber numberWithBool:onThePhone] forKey:ON_THE_PHONE];
    
    CGFloat screenBrightness = [UIScreen mainScreen].brightness;
    [lfData setValue:[NSNumber numberWithFloat:screenBrightness] forKey:SCREEN_BRIGHT];
    
    
    // Add these measurements to the data bundle:
    [self.hfData setValue:lfData forKey:LOW_FREQ];
    
}

- (unsigned long) countField:(NSString *)field
{
    if (![self.hfData valueForKey:field])
    {
        return 0;
    }
    else
    {
        return [[self.hfData valueForKey:field] count];
    }
}

- (void) checkIfDataBundleReadyAndHandleIt
{
    
    unsigned long accCount = [self countField:RAW_ACC_X];
    unsigned long gyrCount = [self countField:RAW_GYR_X];
    unsigned long magCount = [self countField:RAW_MAG_X];
    unsigned long motionCount = [self countField:PROC_GRAV_X];
    
    if (accCount < [self samplesPerBatch] || gyrCount < [self samplesPerBatch] || magCount < [self samplesPerBatch] || motionCount < [self samplesPerBatch])
    {
        return;
    }
    
    NSLog(@"[sensorManager] Collected: %lu acc, %lu gyro, %lu magnet, %lu motion (%@).",accCount,gyrCount,magCount,motionCount,[NSDate date]);
    
    // Add camera data:
    //[self.hfData setValue:[[self cameraProcessor] outputMeasurements] forKey:CAMERA];
    // ADD WAIT FOR WATCH DATA
    
    [self handleFinishedDataBundle];
}

- (void) stopAllSamplers
{
    NSLog(@"[sensorManager] Stopping all sensor sampling.");
    [self.locationManager stopUpdatingLocation];
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopGyroUpdates];
    [self.motionManager stopMagnetometerUpdates];
    [self.motionManager stopDeviceMotionUpdates];
//    [self.cameraProcessor stopSession];
}

- (void) handleFinishedDataBundle
{
    NSLog(@"[sensorManager] Time to wrap the data bundle and send it");
    
    
    // Make sure to stop the sensing:
    [self stopAllSamplers];
    
    //added MFCC extraction here
    [self.soundProcessor processMFCC];

    //[self.timer invalidate];
    [ES_DataBaseAccessor writeSensorData:self.hfData andActivity:self.currentActivity];
    
    // Since we're finished with this activity, stop holding it:
    self.currentActivity = nil;
    
    // Mark finished recording:
    [self.appDelegate markNotRecordingRightNow];
    
}



#pragma mark Location Manager Delegate Methods

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog( @"[sensorManager]:[locationManager] status = %u", status);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *latestLocation = locations.lastObject;
    
    if ([self usingTimerForSampling])
    {
        self.currentLocation = latestLocation;
    }
    else
    {
        [self addLocationSample:latestLocation];
    }
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"[sensorManager]:[locationManager] ERROR: %@ DOMAIN: %@ CODE: %ld", [error localizedDescription], [error domain], (long)[error code]);
}


@end
