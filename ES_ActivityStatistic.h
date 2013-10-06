//
//  ES_ActivityStatistic.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/6/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_User;

@interface ES_ActivityStatistic : NSManagedObject

@property (nonatomic, retain) NSNumber * countActivities;
@property (nonatomic, retain) NSNumber * countBicycling;
@property (nonatomic, retain) NSNumber * countDriving;
@property (nonatomic, retain) NSNumber * countLying;
@property (nonatomic, retain) NSNumber * countRunning;
@property (nonatomic, retain) NSNumber * countSitting;
@property (nonatomic, retain) NSNumber * countStanding;
@property (nonatomic, retain) NSNumber * countWalking;
@property (nonatomic, retain) NSNumber * timeSamplingBegan;
@property (nonatomic, retain) NSNumber * timeSpentSampling;
@property (nonatomic, retain) ES_User *user;

@end
