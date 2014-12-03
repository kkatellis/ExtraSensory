//
//  ES_ActivitiesStrings.m
//  ExtraSensory
//
//  Created by Rafael Aguayo on 2/18/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ActivitiesStrings.h"
#import "ES_DataBaseAccessor.h"
#import "ES_Label.h"

#define LYING_DOWN  @"Lying down"
#define SITTING     @"Sitting"
#define STANDING    @"Standing"
#define WALKING     @"Walking"
#define RUNNING     @"Running"
#define BICYCLING   @"Bicycling"

@interface ES_ActivitiesStrings()

@end


@implementation ES_ActivitiesStrings

static NSArray *mainActivitiesList = nil;
static NSArray *secondaryActivitiesList = nil;
static NSArray *moodsList = nil;
static NSArray *homeSensingList = nil;

static NSArray *mainActivitiesColorList = nil;

+(NSArray *)mainActivities {
    
    if (!mainActivitiesList)
    {
        mainActivitiesList = @[LYING_DOWN, SITTING, STANDING, WALKING, RUNNING, BICYCLING];
    }
    
    return mainActivitiesList;
}

+(NSArray *)mainActivitiesColors
{
    if (!mainActivitiesColorList)
    {
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[self mainActivities].count];
        for (NSString *label in [self mainActivities])
        {
            UIColor *color = [self getColorForMainActivity:label];
            [arr addObject:(id)color.CGColor];
        }
        mainActivitiesColorList = [NSArray arrayWithArray:arr];
    }
    
    return mainActivitiesColorList;
}

+(UIColor *)getColorForMainActivity:(NSString *)activity
{
    if ([activity isEqualToString:LYING_DOWN])
    {
        return [UIColor purpleColor];
    }
    if ([activity isEqualToString:SITTING])
    {
        return [UIColor blueColor];
    }
    if ([activity isEqualToString:STANDING])
    {
        return [UIColor greenColor];
    }
    if ([activity isEqualToString:WALKING])
    {
        return [UIColor yellowColor];
    }
    if ([activity isEqualToString:RUNNING])
    {
        return [UIColor orangeColor];
    }
    if ([activity isEqualToString:BICYCLING])
    {
        return [UIColor redColor];
    }
    
    return [UIColor grayColor];
    
    return nil;
}

+ (NSArray *) loadStringArrayFromTextFile:(NSString *)resourceFilename
{
    NSString *resourceFilePath = [[NSBundle mainBundle] pathForResource:resourceFilename ofType:@"txt"];
    NSError *err = nil;
    NSString *allStrings = [NSString stringWithContentsOfFile:resourceFilePath encoding:NSUTF8StringEncoding error:&err];
    
    if (err)
    {
        NSLog(@"[activitiesStrings] !!! failed to load label strings from file %@. Got error: %@",resourceFilePath,err);
        return nil;
    }
    
    // Separate the labels from the total string:
    NSArray *labelsStrings = [allStrings componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // Sort the labels alphabetically:
    NSMutableArray *sortedLabels = [NSMutableArray arrayWithArray:[labelsStrings sortedArrayUsingSelector:@selector(compare:)]];
    [sortedLabels removeObject:@""];
    
    NSLog(@"[activitiesStrings] Loaded %lu labels from %@.",(unsigned long)sortedLabels.count,resourceFilename);
    
    return sortedLabels;
}

+(NSArray *)secondaryActivities {
    
    if (!secondaryActivitiesList)
    {
        
        secondaryActivitiesList = [self loadStringArrayFromTextFile:@"secondaryActivitiesList"];
    }
    
    return secondaryActivitiesList;
    
}


+(NSArray *)moods {
    if (!moodsList)
    {
        moodsList = [self loadStringArrayFromTextFile:@"moodsList"];
    }
    
    return moodsList;
}

+(NSArray *)homeSensingLabels{
    if (!homeSensingList)
    {
        homeSensingList = [self loadStringArrayFromTextFile:@"homeSensingLabelsList"];
    }
    
    return homeSensingList;
}


/*
 * This is a helping utility function to convert an array of ES_Label objects into an array of Strings.
 */
+ (NSMutableArray *) createStringArrayFromLabelObjectsAraay:(NSArray *)labelObjectsArray
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (id obj in labelObjectsArray)
    {
        if (![obj isKindOfClass:[ES_Label class]])
        {
            NSLog(@"!!! Array contains an item that is not ES_Label");
            return nil;
        }
        ES_Label *label = (ES_Label *)obj;
        [result addObject:label.label];
    }
    
    return result;
}

@end
