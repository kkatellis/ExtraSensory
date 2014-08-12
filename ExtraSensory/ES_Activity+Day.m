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

- (NSString *)getActivityTitle{ //first checks userCorrection
    return (self.userCorrection? self.userCorrection: self.serverPrediction);
}

+ (UIColor *)colorForActivity:(NSString *)activity{
    UIColor *result;
    if ([activity isEqualToString:@"Lying down"]){
        result = [UIColor purpleColor];
    }else if ([activity isEqualToString:@"Sitting"]){
        result = [UIColor blueColor];
    }else if ([activity isEqualToString:@"Standing"]){
        result = [UIColor cyanColor];
    }else if ([activity isEqualToString:@"Running"]){
        result = [UIColor yellowColor];
    }else if ([activity isEqualToString:@"Walking"]){
        result = [UIColor greenColor];
    }else if ([activity isEqualToString:@"Bicycling"]){
        result = [UIColor orangeColor];
    }else if ([activity isEqualToString:@"Driving"]){
        result = [UIColor redColor];
    }else{
        result = [UIColor blackColor];
    }
    return result;
}

@end
