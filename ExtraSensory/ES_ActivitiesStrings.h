//
//  ES_ActivitiesStrings.h
//  ExtraSensory
//
//  Created by Rafael Aguayo on 2/18/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ES_ActivitiesStrings : NSObject

+(NSArray *) mainActivities;

+(NSArray *)mainActivitiesColors;

+(UIColor *)getColorForMainActivity:(NSString *)activity;

+(NSArray *) secondaryActivities;

+(NSArray *)moods;


/*
 * This is a helping utility function to convert an array of ES_Label objects into an array of Strings.
 */
+ (NSMutableArray *) createStringArrayFromLabelObjectsAraay:(NSArray *)labelObjectsArray;

@end
