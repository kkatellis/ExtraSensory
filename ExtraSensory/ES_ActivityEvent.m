//
//  ES_ActivityEvent.m
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/11/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ActivityEvent.h"

@implementation ES_ActivityEvent

- (id)initWithServerPrediction:(NSString *)serverPrediction userCorrection:(NSString *)userCorrection secondaryActivitiesStrings:(NSSet *)secondaryActivitiesStrings moodsStrings:(NSSet *)moodsStrings startTimestamp:(NSNumber *)startTimestamp endTimestamp:(NSNumber *)endTimestamp minuteActivities:(NSMutableArray *)minuteActivities
{
    self = [super init];
    if (self) {
        self.serverPrediction = serverPrediction;
        self.userCorrection = userCorrection;
        self.secondaryActivitiesStrings = secondaryActivitiesStrings;
        self.moodsStrings = moodsStrings;
        self.startTimestamp = startTimestamp;
        self.endTimestamp = endTimestamp;
        self.minuteActivities = minuteActivities;
    }
    return self;
}

@end
