//
//  ES_Settings.h
//  ExtraSensory
//
//  Created by yonatan vaizman on 8/3/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_User;

@interface ES_Settings : NSManagedObject

@property (nonatomic, retain) NSNumber * sampleDuration;
@property (nonatomic, retain) NSNumber * sampleRate;
@property (nonatomic, retain) NSNumber * timeBetweenSampling;
@property (nonatomic, retain) NSNumber * timeBetweenUserNags;
@property (nonatomic, retain) NSNumber * recentTimePeriod;
@property (nonatomic, retain) ES_User *user;

@end
