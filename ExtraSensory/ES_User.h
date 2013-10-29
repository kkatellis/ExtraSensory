//
//  ES_User.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/25/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Activity, ES_ActivityStatistic, ES_Settings;

@interface ES_User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) ES_ActivityStatistic *activityStatistics;
@property (nonatomic, retain) ES_Settings *settings;
@property (nonatomic, retain) NSManagedObject *userPopulation;
@end

@interface ES_User (CoreDataGeneratedAccessors)

- (void)insertObject:(ES_Activity *)value inActivitiesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromActivitiesAtIndex:(NSUInteger)idx;
- (void)insertActivities:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeActivitiesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInActivitiesAtIndex:(NSUInteger)idx withObject:(ES_Activity *)value;
- (void)replaceActivitiesAtIndexes:(NSIndexSet *)indexes withActivities:(NSArray *)values;
- (void)addActivitiesObject:(ES_Activity *)value;
- (void)removeActivitiesObject:(ES_Activity *)value;
- (void)addActivities:(NSOrderedSet *)values;
- (void)removeActivities:(NSOrderedSet *)values;
@end
