//
//  Samples.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/26/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AccelerometerData;

@interface Samples : NSManagedObject

@property (nonatomic, retain) NSString * batchID;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * firstTimeStamp;
@property (nonatomic, retain) NSNumber * sampleFrequency;
@property (nonatomic, retain) AccelerometerData *accelerometerData;


@end
