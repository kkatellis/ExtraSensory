//
//  ES_Activity.h
//  ExtraSensory
//
//  Created by Arya Iranmehr on 8/12/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_User, ES_UserActivityLabels;

@interface ES_Activity : NSManagedObject

@property (nonatomic, retain) NSNumber * isPredictionCorrect;
@property (nonatomic, retain) NSNumber * isPredictionVerified;
@property (nonatomic, retain) NSString * mood;
@property (nonatomic, retain) NSString * serverPrediction;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSString * userCorrection;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) ES_User *user;
@property (nonatomic, retain) NSSet *userActivityLabels;
@end

@interface ES_Activity (CoreDataGeneratedAccessors)

- (void)addUserActivityLabelsObject:(ES_UserActivityLabels *)value;
- (void)removeUserActivityLabelsObject:(ES_UserActivityLabels *)value;
- (void)addUserActivityLabels:(NSSet *)values;
- (void)removeUserActivityLabels:(NSSet *)values;

@end
