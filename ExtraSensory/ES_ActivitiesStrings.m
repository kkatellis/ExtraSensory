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
#define STANDING_IN_PLACE    @"Standing in place"
#define STANDING_AND_MOVING  @"Standing and moving"
#define WALKING     @"Walking"
#define RUNNING     @"Running"
#define BICYCLING   @"Bicycling"

@interface ES_ActivitiesStrings()

@end


@implementation ES_ActivitiesStrings

static NSArray *mainActivitiesList = nil;
static NSArray *secondaryActivitiesList = nil;
static NSDictionary *secondaryActivitiesPerSubject = nil;
static NSArray *moodsList = nil;
static NSArray *homeSensingList = nil;

static NSArray *mainActivitiesColorList = nil;

+(NSArray *)mainActivities {
    
    if (!mainActivitiesList)
    {
        mainActivitiesList = [self loadStringArrayFromTextFile:@"mainActivitiesList" andSortLabels:NO];
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
        return [UIColor magentaColor];
    }
    if ([activity isEqualToString:SITTING])
    {
        return [UIColor purpleColor];
    }
    if ([activity isEqualToString:STANDING_IN_PLACE])
    {
        return [UIColor blueColor];
    }
    if ([activity isEqualToString:STANDING_AND_MOVING])
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

+ (NSArray *) loadStringArrayFromTextFile:(NSString *)resourceFilename andSortLabels:(BOOL)sort
{
    NSDictionary *dictRef = nil;
    NSArray *arr = [self loadStringArrayFromTextFile:resourceFilename andLoadSubjectsDictionaryInto:&dictRef andSortLabels:sort];
    return arr;
}

+ (NSArray *) loadStringArrayFromTextFile:(NSString *)resourceFilename andLoadSubjectsDictionaryInto:(NSDictionary **)dictRef andSortLabels:(BOOL)sort
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
    NSMutableArray *sortedLabels;
    if (sort) {
        // Sort the labels alphabetically:
        sortedLabels = [NSMutableArray arrayWithArray:[labelsStrings sortedArrayUsingSelector:@selector(compare:)]];
    }
    else {
        sortedLabels = [NSMutableArray arrayWithArray:labelsStrings];
    }
    [sortedLabels removeObject:@""];
    
    NSLog(@"[activitiesStrings] Loaded %lu labels from %@.",(unsigned long)sortedLabels.count,resourceFilename);
    
    // See if some of the strings include specification of keys/subjects:
    NSMutableDictionary *dict = [NSMutableDictionary new];
    for (int ii = 0; ii < sortedLabels.count; ii ++)
    {
        NSString *line = [sortedLabels objectAtIndex:ii];
        NSArray *parts = [line componentsSeparatedByString:@"|"];
        if ([parts count] > 1)
        {
            // Then the first part is the label itself:
            NSString *theLabel = parts[0];
            [sortedLabels replaceObjectAtIndex:ii withObject:theLabel];
            // And the second part should be the label's relevant subjects, separated by comma:
            NSArray *subjects = [parts[1] componentsSeparatedByString:@","];
            for (NSString *subject in subjects)
            {
                if (![dict objectForKey:subject])
                {
                    [dict setObject:[NSMutableArray new] forKey:subject];
                }
                [[dict objectForKey:subject] addObject:theLabel];
            }
        }
    }
    
    // Assign the created dictionary to the reference:
    *dictRef = dict;
    
    return sortedLabels;
}

+ (void) loadSecondary
{
    NSDictionary *subjDict = nil;
    secondaryActivitiesList = [self loadStringArrayFromTextFile:@"secondaryActivitiesList" andLoadSubjectsDictionaryInto:&subjDict andSortLabels:YES];
    secondaryActivitiesPerSubject = subjDict;
    NSLog(@"[activitiesStrings] Loaded secondary subjects: %@",subjDict);
}

+(NSArray *)secondaryActivities {
    
    if (!secondaryActivitiesList)
    {
        [self loadSecondary];
    }
    
    return secondaryActivitiesList;
    
}

+(NSDictionary *)secondaryActivitiesPerSubject
{
    if (!secondaryActivitiesList)
    {
        [self loadSecondary];
    }
    
    return secondaryActivitiesPerSubject;
}


+(NSArray *)moods {
    if (!moodsList)
    {
        moodsList = [self loadStringArrayFromTextFile:@"moodsList" andSortLabels:YES];
    }
    
    return moodsList;
}

+(NSArray *)homeSensingLabels{
    if (!homeSensingList)
    {
        homeSensingList = [self loadStringArrayFromTextFile:@"homeSensingLabelsList" andSortLabels:YES];
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
