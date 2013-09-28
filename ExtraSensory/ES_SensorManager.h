//
//  ES_SensorManager.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>



@class ES_AccelerometerAccessor;

//public interface
@interface ES_SensorManager : NSObject

@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) ES_AccelerometerAccessor *accelerometer;

- (ES_AccelerometerAccessor *) accelerometer;


@end
