//
//  AccelerometerSample.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SampleSet;

@interface AccelerometerSample : NSManagedObject

@property (nonatomic, retain) NSNumber * x;
@property (nonatomic, retain) NSNumber * y;
@property (nonatomic, retain) NSNumber * z;
@property (nonatomic, retain) NSDecimalNumber * time;
@property (nonatomic, retain) SampleSet *sampleSet;

@end
