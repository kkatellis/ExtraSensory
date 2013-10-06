//
//  ES_User.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/6/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_User.h"
#import "ES_Activity.h"
#import "ES_ActivityStatistic.h"
#import "ES_Settings.h"


@implementation ES_User

@dynamic name;
@dynamic uuid;
@dynamic activities;
@dynamic activityStatistics;
@dynamic settings;

- (void)addActivitiesObject:(ES_Activity *)value
{
    NSMutableOrderedSet *tempSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.activities];
    [tempSet addObject:value];
    self.activities = tempSet;
}

@end
