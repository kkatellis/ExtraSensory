	//
//  ES_Activity.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/6/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_SensorSample, ES_User, ES_UserActivityLabel;

@interface ES_Activity : NSManagedObject

@property (nonatomic, retain) NSNumber * isPredictionCorrect;
@property (nonatomic, retain) NSNumber * isPredictionVerified;
@property (nonatomic, retain) NSNumber * numberOfSamples;
@property (nonatomic, retain) NSNumber * sampleFrequency;
@property (nonatomic, retain) NSString * serverPrediction;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSString * userCorrection;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * hasBeenSent;
@property (nonatomic, retain) NSString * zipFilePath;
@property (nonatomic, retain) NSOrderedSet *sensorSamples;
@property (nonatomic, retain) ES_User *user;
@property (nonatomic, retain) NSSet *userActivityLabels;
@property (nonatomic, retain) NSString *mood;

//-(id) copyWithZone: (NSZone *) zone;
@end

@interface ES_Activity (CoreDataGeneratedAccessors)

- (void)insertObject:(ES_SensorSample *)value inSensorSamplesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSensorSamplesAtIndex:(NSUInteger)idx;
- (void)insertSensorSamples:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSensorSamplesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSensorSamplesAtIndex:(NSUInteger)idx withObject:(ES_SensorSample *)value;
- (void)replaceSensorSamplesAtIndexes:(NSIndexSet *)indexes withSensorSamples:(NSArray *)values;
- (void)addSensorSamplesObject:(ES_SensorSample *)value;
- (void)removeSensorSamplesObject:(ES_SensorSample *)value;
- (void)addSensorSamples:(NSOrderedSet *)values;
- (void)removeSensorSamples:(NSOrderedSet *)values;
- (void)addUserActivityLabelsObject:(ES_UserActivityLabel *)value;
- (void)removeUserActivityLabelsObject:(ES_UserActivityLabel *)value;
- (void)addUserActivityLabels:(NSSet *)values;
- (void)removeUserActivityLabels:(NSSet *)values;

@end
