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



@class ES_AccelerometerAccessor, ES_User, ES_Activity;

//public interface
@interface ES_SensorManager : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    
    CLLocation *currentLocation;
    
}

@property (strong, nonatomic) CLLocation *currentLocation;

@property (strong, nonatomic) CLLocation *previousLocation;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (nonatomic) double sampleFrequency; // Hertz
@property (nonatomic) double sampleDuration;  // Seconds

@property (nonatomic, strong) NSNumber *isReady;

@property (nonatomic, weak) ES_User *user;

@property (nonatomic, strong) ES_Activity *currentActivity;

- (BOOL) record;



@end
