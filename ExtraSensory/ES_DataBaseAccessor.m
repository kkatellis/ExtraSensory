//
//  ES_DataBaseAccessor.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_DataBaseAccessor.h"
#import "ES_AppDelegate.h"

@implementation ES_DataBaseAccessor

// private methods

+ (NSManagedObjectContext *)context
{
    return [(ES_AppDelegate *)UIApplication.sharedApplication.delegate managedObjectContext];
}

// public methods

+ (NSArray *) read: (NSString *)entityDescription
{
    NSError *error = [[NSError alloc] init];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:[self context]];
    
    [request setEntity:entity];
    
    return [[self context] executeFetchRequest:request error:&error];
}

+ (NSManagedObject *) write:(NSString *)entityDescription
{
    return [NSEntityDescription insertNewObjectForEntityForName:entityDescription inManagedObjectContext: [self context]];
}

+ (void) save
{
    NSError *error = [[NSError alloc] init];
    
    if (![[self context] save:&error])
    {
        NSLog(@"Error saving sample data!");
    }
}

@end
