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

+ (NSMutableArray *) createStringArrayFromUserActivityLabelsAraay:(NSArray *)userActivityLabelsArray
{
    NSLog(@"=== in createStringArray1");
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSLog(@"=== in createStringArray2");
    for (id obj in userActivityLabelsArray)
    {
        NSLog(@"=== object in array: %@ with type %@",obj,[obj class]);
        if (![obj isKindOfClass:[ES_UserActivityLabels class]])
        {
            NSLog(@"!!! Array contains an item that is not ES_UserActivityLabels");
            return nil;
        }
        ES_UserActivityLabels *userActivityLabels = (ES_UserActivityLabels *)obj;
        NSLog(@"=== createStrAr before add %@",userActivityLabels.name);
        [result addObject:userActivityLabels.name];
        NSLog(@"=== createStrAr after add %@",userActivityLabels.name);
    }
    
    return result;
}

@end
