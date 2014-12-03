//
//  ES_Activity.h
//  ExtraSensory
//
//  Created by yonatan vaizman on 11/25/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Mood, ES_SecondaryActivity, ES_User;

@interface ES_Activity : NSManagedObject

@property (nonatomic, retain) NSString * serverPrediction;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSString * userCorrection;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSSet *moods;
@property (nonatomic, retain) NSSet *secondaryActivities;
@property (nonatomic, retain) ES_User *user;
@end

@interface ES_Activity (CoreDataGeneratedAccessors)

- (void)addMoodsObject:(ES_Mood *)value;
- (void)removeMoodsObject:(ES_Mood *)value;
- (void)addMoods:(NSSet *)values;
- (void)removeMoods:(NSSet *)values;

- (void)addSecondaryActivitiesObject:(ES_SecondaryActivity *)value;
- (void)removeSecondaryActivitiesObject:(ES_SecondaryActivity *)value;
- (void)addSecondaryActivities:(NSSet *)values;
- (void)removeSecondaryActivities:(NSSet *)values;

@end
