//
//  ES_Format.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/11/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *  ES_Activity
 *
 *  Discussion:
 *      Specifies an activity type.
 *
 */
typedef enum {
    kES_Lying,
	kES_Sitting,
	kES_Standing,
	kES_Walking,
    kES_Running,
    kES_Bicycling,
    kES_Driving
} kES_Activity;

@interface ES_Format : NSObject

+ (UIColor *)colorForActivity: (kES_Activity)activity;

@end
