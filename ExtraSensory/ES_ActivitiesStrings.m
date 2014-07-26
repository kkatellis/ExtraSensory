//
//  ES_ActivitiesStrings.m
//  ExtraSensory
//
//  Created by Rafael Aguayo on 2/18/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ActivitiesStrings.h"
#import "ES_DataBaseAccessor.h"

@interface ES_ActivitiesStrings()

@end


@implementation ES_ActivitiesStrings

static NSArray *mainActivitiesList = nil;
static NSArray *secondaryActivitiesList = nil;
static NSArray *moodsList = nil;

+(NSArray *)mainActivities {
    
    if (!mainActivitiesList)
    {
        mainActivitiesList = [@[@"Lying down", @"Sitting", @"Standing", @"Walking", @"Running", @"Bicycling", @"Driving"] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return mainActivitiesList;
}

+(NSArray *)secondaryActivities {
    
    if (!secondaryActivitiesList)
    {
        secondaryActivitiesList = [@[@"Lifting weights", @"Playing baseball", @"Playing basketball", @"Playing lacrosse", @"Skateboarding", @"Playing soccer", @"Playing frisbee", @"Stretching", @"Yoga", @"Elliptical machine", @"Treadmill", @"Stationary Bike", @"Cooking", @"Cleaning", @"Gardening", @"Doing laundry", @"Mowing the lawn", @"Raking the leaves", @"Vacuuming", @"Doing dishes", @"Washing car", @"Manual labor", @"Dancing", @"Driving", @"Eating", @"Drinking",@"Jumping", @"Listening to music", @"Relaxing", @"Shopping", @"Sleeping", @"Talking with friends", @"Using the bathroom", @"Playing videogames", @"Watching TV", @"Lab work", @"Written work", @"Drawing", @"Surfing the internet", @"Computer work", @"Reading a book", @"Studying", @"In class", @"In a meeting", @"Texting", @"At a bar", @"At a concert", @"At the beach", @"At a restaurant", @"On a bus", @"On a plane", @"On a train", @"In a car"] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    // Dynamically find out what are the most common activities of the user:
    NSArray *sortedSecondaryActivities = [self sortedSecondaryActivities];
 
    return sortedSecondaryActivities;
}

+(NSArray *)sortedSecondaryActivities
{
    
    NSDictionary *secondaryActivityCounts = [ES_DataBaseAccessor getTodaysCountsForSecondaryActivities:secondaryActivitiesList];
    
    
    // Separate the activities to those that have been used and those that haven't:
    NSMutableArray *usedActivities = [[NSMutableArray alloc] initWithCapacity:[secondaryActivitiesList count]];
    NSMutableArray *usedActivitiesCountValues = [[NSMutableArray alloc] initWithCapacity:[secondaryActivitiesList count]];
    NSMutableArray *unusedActivities = [[NSMutableArray alloc] initWithCapacity:[secondaryActivitiesList count]];

    for (NSString *act in secondaryActivitiesList)
    {
        if ([[secondaryActivityCounts valueForKey:act] integerValue] > 0)
        {
            [usedActivities addObject:act];
            [usedActivitiesCountValues addObject:[secondaryActivityCounts valueForKey:act]];
        }
        else
        {
            [unusedActivities addObject:act];
        }
    }
    
    NSDictionary *usedActivitiesCounts = [NSDictionary dictionaryWithObjects:usedActivitiesCountValues forKeys:usedActivities];
    
    NSArray *sortedUsedActivities = [usedActivitiesCounts keysSortedByValueUsingSelector:@selector(compare:)];
    // Since this sorts from least used to most used, reverse the order:
    sortedUsedActivities = [[sortedUsedActivities reverseObjectEnumerator] allObjects];
    
    NSMutableArray *sortedAllActivities = [NSMutableArray arrayWithArray:sortedUsedActivities];
    [sortedAllActivities addObjectsFromArray:unusedActivities];

    return sortedAllActivities;
    
}

+(NSArray *)moods {
    if (!moodsList)
    {
        moodsList = [@[@"Amused",@"Angry",@"Bored",@"Calm",@"Crazy",@"Disgusted",@"Dreamy",@"Energetic",@"Excited",@"Frustrated",@"Happy",@"High",@"Hungry",@"In love", @"Lonely", @"Normal", @"Nostalgic", @"Optimistic", @"Romantic", @"Sad", @"Serious", @"Sexy", @"Sleepy", @"Stressed", @"Tired", @"Untroubled", @"Worried"] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return moodsList;
}

@end
