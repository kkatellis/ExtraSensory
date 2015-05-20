//
//  ES_SensorManager.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//
//
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <AVFoundation/AVFoundation.h>
#import "ES_SoundWaveProcessor.h"
#include <PebbleKit/PebbleKit.h>
#import "ES_WatchProcessor.h"



@class ES_AccelerometerAccessor, ES_User, ES_Activity, ES_SoundWaveProcessor;

//public interface
@interface ES_SensorManager : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    
    
    @private
    //-// HF Data Management
    NSMutableArray      *HFDataBundle;      // Holds data over entire interval of HF Sampling, sends after full
    NSString            *HFFilePath;        // Path that will eventually hold HFDataBundle;
}

@property(strong, nonatomic)ES_SoundWaveProcessor *soundProcessor;


@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CTCallCenter *callCenter;

@property (nonatomic) double sampleFrequency; // Hertz
@property (nonatomic) double interval; // seconds
@property (nonatomic) double sampleDuration;  // Seconds

@property (nonatomic, strong) NSNumber *isReady;

@property (nonatomic, weak) ES_User *user;

@property (nonatomic, strong) ES_Activity *currentActivity;

- (BOOL) record;
-(void) turnOffRecording;
-(void) _prepStage:(NSString*) fileName;


@end
