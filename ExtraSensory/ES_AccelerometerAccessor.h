//
//  ES_AccelerometerAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@class ES_SensorManager;

// Public interface
@interface ES_AccelerometerAccessor : NSObject

@property (strong, nonatomic) NSNumber *frequency;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) ES_SensorManager *sensorManager;

@property (nonatomic) NSTimeInterval recordDuration;


-(void)record;


@end
