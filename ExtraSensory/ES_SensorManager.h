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

@property NSArray *acc_xyzt;
@property NSArray *gyro_xyzt;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CLLocationManager *locationManager;

- (void) record;


@end
