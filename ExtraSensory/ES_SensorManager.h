//
//  ES_SensorManager.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>



@class ES_AccelerometerAccessor;

//public interface
@interface ES_SensorManager : NSObject

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (nonatomic) double sampleFrequency; // Hertz
@property (nonatomic) double sampleDuration;  // Seconds

- (void) record;

@end
