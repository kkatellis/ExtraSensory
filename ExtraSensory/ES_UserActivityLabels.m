//
//  ES_UserActivityLabels.m
//  ExtraSensory
//
//  Created by Kat Ellis on 3/17/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_UserActivityLabels.h"
#import "ES_Activity.h"


@implementation ES_UserActivityLabels

@dynamic name;
@dynamic activity;

/*
 * This is a helping utility function to convert an array of ES_UserActivityLabels objects into an array of Strings.
 */
+ (NSMutableArray *) createStringArrayFromUserActivityLabelsAraay:(NSArray *)userActivityLabelsArray
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (id obj in userActivityLabelsArray)
    {
        if (![obj isKindOfClass:[ES_UserActivityLabels class]])
        {
            NSLog(@"!!! Array contains an item that is not ES_UserActivityLabels");
            return nil;
        }
        ES_UserActivityLabels *userActivityLabels = (ES_UserActivityLabels *)obj;
        [result addObject:userActivityLabels.name];
    }
    
    return result;
}

@end
