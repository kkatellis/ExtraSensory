//
//  ES_Sensors.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

// Public interface
@interface ES_Sensors : NSObject

@property (nonatomic) NSNumber *frequency;

-(void)startRecordingAccelerometer;
-(void)stopRecordingAccelerometer;

//-(NSNumber *)frequency;


@end
