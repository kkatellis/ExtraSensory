//
//  ES_ActivityEvent.h
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/11/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ES_Activity.h"

@interface ES_ActivityEvent : NSObject


@property (nonatomic, retain) NSString * serverPrediction;
@property (nonatomic, retain) NSString * userCorrection;
@property (nonatomic, retain) NSSet * secondaryActivitiesStrings;
@property (nonatomic, retain) NSSet * moodsStrings;
@property (nonatomic, retain) NSNumber * startTimestamp;
@property (nonatomic, retain) NSNumber * endTimestamp;

@property (nonatomic, retain) NSMutableArray *minuteActivities;

- (id)initWithServerPrediction:(NSString *)serverPrediction userCorrection:(NSString *)userCorrection secondaryActivitiesStrings:(NSSet *)secondaryActivitiesStrings moodsStrings:(NSSet *)moodsStrings startTimestamp:(NSNumber *)startTimestamp endTimestamp:(NSNumber *)endTimestamp minuteActivities:(NSMutableArray *)minuteActivities;


@end
