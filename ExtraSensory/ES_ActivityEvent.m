//
//  ES_ActivityEvent.m
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/11/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ActivityEvent.h"

@implementation ES_ActivityEvent

- (id)initWithIsVerified:(NSNumber *)isPredictionVerified serverPrediction:(NSString *)serverPrediction userCorrection:(NSString *)userCorrection userActivityLabels:(NSSet *)userActivityLabels startTimestamp:(NSNumber *)startTimestamp endTimestamp:(NSNumber *)endTimestamp startActivity:(ES_Activity *)startActivity
{
    self = [super init];
    if (self) {
        self.isPredictionVerified = isPredictionVerified;
        self.serverPrediction = serverPrediction;
        self.userCorrection = userCorrection;
        self.userActivityLabels = userActivityLabels;
        self.startTimestamp = startTimestamp;
        self.endTimestamp = endTimestamp;
        self.startActivity = startActivity;
    }
    return self;
}

@end
