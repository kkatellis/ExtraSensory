//
//  ES_SensorManager.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_SensorManager.h"
#import "ES_AccelerometerAccessor.h"
#import "ES_AppDelegate.h"


@implementation ES_SensorManager

@synthesize accelerometer = _accelerometer;

// Getter
- (NSManagedObjectContext *) managedObjectContext
{
    if (!_managedObjectContext)
    {
        ES_AppDelegate *appDelegate = UIApplication.sharedApplication.delegate;
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}


- (CMMotionManager *)motionManager
{
    if (!_motionManager) _motionManager = [[CMMotionManager alloc] init];
    return _motionManager;
}

- (ES_AccelerometerAccessor *) accelerometer
{
    if (!_accelerometer)
    {
        _accelerometer = [[ES_AccelerometerAccessor alloc] init];
    }
    _accelerometer.motionManager = self.motionManager;

    
    return _accelerometer;
}


@end
