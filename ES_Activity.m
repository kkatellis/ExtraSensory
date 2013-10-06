//
//  ES_Activity.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/6/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_Activity.h"
#import "ES_SensorSample.h"
#import "ES_User.h"
#import "ES_UserActivityLabel.h"


@implementation ES_Activity

@dynamic isPredictionCorrect;
@dynamic isPredictionVerified;
@dynamic numberOfSamples;
@dynamic sampleFrequency;
@dynamic serverPrediction;
@dynamic timestamp;
@dynamic userCorrection;
@dynamic uuid;
@dynamic hasBeenSent;
@dynamic zipFilePath;
@dynamic sensorSamples;
@dynamic user;
@dynamic userActivityLabels;

- (void)addSensorSamplesObject:(ES_SensorSample *)value
{
    NSMutableOrderedSet *tempSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.sensorSamples];
    [tempSet addObject:value];
    self.sensorSamples = tempSet;
}

@end
