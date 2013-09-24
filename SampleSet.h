//
//  SampleSet.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AccelerometerSample, User;

@interface SampleSet : NSManagedObject

@property (nonatomic, retain) NSSet *accelerometerSamples;
@property (nonatomic, retain) User *user;
@end

@interface SampleSet (CoreDataGeneratedAccessors)

- (void)addAccelerometerSamplesObject:(AccelerometerSample *)value;
- (void)removeAccelerometerSamplesObject:(AccelerometerSample *)value;
- (void)addAccelerometerSamples:(NSSet *)values;
- (void)removeAccelerometerSamples:(NSSet *)values;

@end
