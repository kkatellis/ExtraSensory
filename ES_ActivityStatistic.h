//
//  ES_ActivityStatistic.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_User;

@interface ES_ActivityStatistic : NSManagedObject

@property (nonatomic, retain) NSString * statistic;
@property (nonatomic, retain) NSNumber * value;
@property (nonatomic, retain) ES_User *user;

@end
