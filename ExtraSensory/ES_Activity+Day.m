//
//  ES_Activity+Day.m
//  ExtraSensory
//
//  Created by Arya Iranmehr on 7/21/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_Activity+Day.h"

@implementation ES_Activity (Day)
- (NSDate *)day
{
    return [self.startTime beginningOfDay];
}

@end
