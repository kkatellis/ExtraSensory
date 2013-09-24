//
//  ES_Sensors.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_Sensors.h"


// Private interface
@interface ES_Sensors()

@property (strong, nonatomic) CMMotionManager *motion;



@end


@implementation ES_Sensors

@synthesize motion = _motion;

// Getter
- (CMMotionManager *)motion
{
    if (!_motion) _motion = [[CMMotionManager alloc] init];
    return _motion;
}

- (void) recordAccelerometer
{
    self.motion.accelerometerUpdateInterval = .1;
    
    ES_Sensors * __weak weakSelf = self;
    if ([weakSelf.motion isAccelerometerAvailable]) {
        if (![weakSelf.motion isAccelerometerActive])
            [weakSelf.motion startAccelerometerUpdatesToQueue: [NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accData, NSError *error){
                
                NSLog( @"%f", accData.acceleration.x );
                NSLog( @"%f", accData.acceleration.y );
                NSLog( @"%f", accData.acceleration.z );
                
            }];
    }
}


@end
