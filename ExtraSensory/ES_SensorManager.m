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

@property (nonatomic) NSArray *batchData;

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

@synthesize batchData = _batchData;

@synthesize isReady = _isReady;

- (NSNumber *) isReady
{
    if ( _isReady == nil )
    {
        _isReady = [NSNumber numberWithBool: YES];
    }
    return _isReady;
}


// Getter

- (NSArray *)batchData
{
    if (!_batchData)
    {
        _batchData = [NSArray new];
    }
    return _batchData;
}

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


- (BOOL) record
{
    if (!self.isReady)
    {
        return NO;
    }
    
    //NSLog( @"record" );
    
    double interval = (1.0 / self.sampleFrequency);
    
    self.motionManager.accelerometerUpdateInterval = interval;
    self.motionManager.gyroUpdateInterval = interval;
    
    NSLog( @"LocAuthStatus: %u", [CLLocationManager authorizationStatus]);
    
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [self.locationManager startUpdatingLocation];
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


- (NSArray *) keys
{
    return [NSArray arrayWithObjects: @"speed", @"lat", @"long", @"timestamp", @"gyro_x", @"acc_x", @"gyro_y", @"acc_y", @"gyro_z", @"acc_z", @"mic_peak_db",  @"mic_avg_db", nil ];
}

- (void) readSensorsIntoDictionary
{
    //NSLog( @"readSensorsIntoDictionary" );
    
    __block ES_SensorManager *blockSelf = self;
    
    dispatch_async(self.sensorQueue, ^
                   {
                       NSArray *objects = [NSArray new];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.locationManager.location.speed ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.locationManager.location.coordinate.latitude ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.locationManager.location.coordinate.longitude ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.motionManager.accelerometerData.timestamp ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.motionManager.gyroData.rotationRate.x ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.motionManager.accelerometerData.acceleration.x ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.motionManager.gyroData.rotationRate.y ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.motionManager.accelerometerData.acceleration.y ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.motionManager.gyroData.rotationRate.z ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: self.motionManager.accelerometerData.acceleration.z ]];
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: 0.0 ]]; // placeholder for mic_peak_db
                       objects = [objects arrayByAddingObject: [NSNumber numberWithDouble: 0.0 ]]; // placeholder for mic_avg_db
                       
                       NSDictionary *dictionary = [NSDictionary dictionaryWithObjects: objects forKeys: [blockSelf keys]];
                       
                       blockSelf.batchData = [blockSelf.batchData arrayByAddingObject: dictionary];
                       
                       blockSelf.counter = [NSNumber numberWithInteger: [blockSelf.counter integerValue] + 1];
                       
                       if ([blockSelf.counter integerValue] >= self.samplesPerBatch )
                       {
                           [blockSelf.timer invalidate];
                           
                           blockSelf.counter = 0;
                           
                           [blockSelf.locationManager stopUpdatingLocation];
                           [blockSelf.motionManager stopAccelerometerUpdates];
                           [blockSelf.motionManager stopGyroUpdates];
                           
                           
                           //NSLog( @"%@", [blockSelf.batchData description]);
                           
                           NSError * error = [NSError new];
                           
                           NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: blockSelf.batchData options:0 error:&error];
                           
                           NSString *filePath = [[ES_DataBaseAccessor dataDirectory] stringByAppendingString: @"/HF_DUR_DATA.txt"];
                           
                           BOOL writeFileSuccess = [jsonObject writeToFile: filePath atomically:YES];
                           
                           if (writeFileSuccess)
                           {
                               //NSLog(@"Data successfully written to file");
                           }
                           
                           self.isReady = [NSNumber numberWithBool: YES];
                           
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
