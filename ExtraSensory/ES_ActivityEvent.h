//
//  ES_ActivityEvent.h
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/11/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ES_ActivityEvent : NSObject

@property (nonatomic, retain) NSNumber * isPredictionVerified;

@property (nonatomic, retain) NSString * serverPrediction;
@property (nonatomic, retain) NSString * userCorrection;
@property (nonatomic, retain) NSSet *userActivityLabels;

@property (nonatomic, retain) NSNumber * startTimestamp;
@property (nonatomic, retain) NSNumber * endTimestamp;

- (id)initWithIsVerified:(NSNumber *)isPredictionVerified serverPrediction:(NSString *)serverPrediction userCorrection:(NSString *)userCorrection userActivityLabels:(NSSet *)userActivityLabels startTimestamp:(NSNumber *)startTimestamp endTimestamp:(NSNumber *)endTimestamp;

@end
