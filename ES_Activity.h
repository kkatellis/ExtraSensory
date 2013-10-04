//
//  ES_Activity.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Sample, ES_User, ES_UserActivityLabel;

@interface ES_Activity : NSManagedObject

@property (nonatomic, retain) NSNumber * numberOfSamples;
@property (nonatomic, retain) NSNumber * sampleFrequency;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSString * prediction;
@property (nonatomic, retain) NSNumber * userAgrees;
@property (nonatomic, retain) NSOrderedSet *sensorSamples;
@property (nonatomic, retain) ES_User *user;
@property (nonatomic, retain) NSSet *userActivityLabels;
@end

@interface ES_Activity (CoreDataGeneratedAccessors)

- (void)insertObject:(ES_Sample *)value inSensorSamplesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSensorSamplesAtIndex:(NSUInteger)idx;
- (void)insertSensorSamples:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSensorSamplesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSensorSamplesAtIndex:(NSUInteger)idx withObject:(ES_Sample *)value;
- (void)replaceSensorSamplesAtIndexes:(NSIndexSet *)indexes withSensorSamples:(NSArray *)values;
- (void)addSensorSamplesObject:(ES_Sample *)value;
- (void)removeSensorSamplesObject:(ES_Sample *)value;
- (void)addSensorSamples:(NSOrderedSet *)values;
- (void)removeSensorSamples:(NSOrderedSet *)values;
- (void)addUserActivityLabelsObject:(ES_UserActivityLabel *)value;
- (void)removeUserActivityLabelsObject:(ES_UserActivityLabel *)value;
- (void)addUserActivityLabels:(NSSet *)values;
- (void)removeUserActivityLabels:(NSSet *)values;

@end
