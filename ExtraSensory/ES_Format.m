//
//  ES_Format.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/11/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_Format.h"


@implementation ES_Format

+ (UIColor *)colorForActivity: (kES_Activity)activity
{
    UIColor *result;
    switch (activity) {
        case kES_Lying:
            result = [UIColor purpleColor];
            break;
            
        case kES_Sitting:
            result = [UIColor blueColor];
            break;
            
        case kES_Standing:
            result = [UIColor cyanColor];
            break;
            
        case kES_Walking:
            result = [UIColor greenColor];
            break;
            
        case kES_Running:
            result = [UIColor yellowColor];
            break;
            
        case kES_Bicycling:
            result = [UIColor orangeColor];
            break;
            
        case kES_Driving:
            result = [UIColor redColor];
            break;
            
        default:
            result = [UIColor blackColor];
            break;
    }
    return result;
}

@end
