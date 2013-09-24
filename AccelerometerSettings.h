//
//  AccelerometerSettings.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Settings;

@interface AccelerometerSettings : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber *sampleFrequency;
@property (nonatomic, retain) NSNumber *enabled;
@property (nonatomic, retain) NSNumber *active;
@property (nonatomic, retain) NSNumber *available;
@property (nonatomic, retain) Settings *settings;

@end
