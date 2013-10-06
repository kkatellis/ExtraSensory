//
//  ES_DataBaseAccessor.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_DataBaseAccessor.h"
#import "ES_AppDelegate.h"
#import "ZipArchive.h"
#import "ES_NetworkAccessor.h"
#import "ES_User.h"
#import "ES_Activity.h"
#import "ES_ActivityStatistic.h"
#import "ES_SensorSample.h"

@implementation ES_DataBaseAccessor

#define ROOT_DATA_OBJECT @"ES_User"

+ (ES_User *)user
{
    ES_User *user;
    
    NSError *error = [NSError new];
    
    NSFetchRequest *request = [NSFetchRequest new];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: ROOT_DATA_OBJECT inManagedObjectContext: [self context]];
    
    [request setEntity:entity];
    
    NSArray *users = [[self context] executeFetchRequest:request error:&error];
    
    if ([users count] == 0)
    {
        NSLog(@"Initializing user for the first time!");
        user = [NSEntityDescription insertNewObjectForEntityForName: ROOT_DATA_OBJECT inManagedObjectContext: [self context]];
        user.settings = [NSEntityDescription insertNewObjectForEntityForName: @"ES_Settings" inManagedObjectContext:[self context]];
        user.activityStatistics = [NSEntityDescription insertNewObjectForEntityForName:@"ES_ActivityStatistics" inManagedObjectContext:[self context]];
        user.uuid = [[NSUUID UUID] UUIDString];
        user.activityStatistics.timeSamplingBegan = [NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]];
        
        [self save];
    }
    else if ([users count] == 1)
    {
        NSLog(@"Getting user from database");
        user = [users objectAtIndex: 0];
    }
    else
    {
        NSLog( @"Why are there %lu users in the database??", (unsigned long)[users count] );
    }
    return user;
}

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

+ (ES_Activity *) newActivity
{
    return [NSEntityDescription insertNewObjectForEntityForName: @"ES_Activity" inManagedObjectContext:[self context]];
}

+ (ES_SensorSample *) newSensorSample
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"ES_SensorSample" inManagedObjectContext:[self context]];
}

+ (ES_Activity *) getActivityWithTime: (NSNumber *)time
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ES_Activity" inManagedObjectContext:[self context]];
    [fetchRequest setEntity:entity];
    
    NSString *attributeValue = [NSString stringWithFormat: @"%@", time];
    
    NSLog(@"attributeValue = %@", attributeValue );
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(timestamp == %@)", attributeValue ];
    
    [fetchRequest setPredicate:predicate];
    
    NSError *error = [NSError new];
    
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    NSLog(@"number of matching hits = %lu", (unsigned long)[results count]);
   // NSLog(@"error: %@", [error localizedDescription]);
    
    if ([results count] > 0 )
    {
        return [results objectAtIndex: 0];
    }
    else return nil;
    
    for ( id a in results )
    {
        NSLog(@"result: %@", a);
    }
}

+ (void) save
{
    NSError *error = [[NSError alloc] init];
    
    if (![[self context] save:&error])
    {
        NSLog(@"%@", [error localizedDescription]);
    }
}

+ (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *) dataDirectory
{
    NSString *directory = [[self applicationDocumentsDirectory] stringByAppendingString: @"/data"];
    
    NSFileManager *fileManager= [NSFileManager defaultManager];
    
    BOOL isDir;
    
    if (![fileManager fileExistsAtPath:directory isDirectory: &isDir ])
    {
        NSError *error = nil;
        if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error])
        {
            NSLog(@"Failed to create directory \"%@\". Error: %@", directory, error);
        }
    }
    return directory;
}

+ (NSString *) zipDirectory
{
    NSString *directory = [[self applicationDocumentsDirectory] stringByAppendingString: @"/zip"];
    
    NSFileManager *fileManager= [NSFileManager defaultManager];
    
    BOOL isDir;
    
    if (![fileManager fileExistsAtPath:directory isDirectory: &isDir ])
    {
        NSError *error = nil;
        if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error])
        {
            NSLog(@"Failed to create directory \"%@\". Error: %@", directory, error);
        }
    }
    return directory;
}

+ (NSString *) zipFileName2: (NSString *)time
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSLog(@"time for zip name = %0.0f", [time doubleValue] );
    return [NSString stringWithFormat:@"/%@-%@", time, appDelegate.user.uuid];
}


+ (void) zipFilesWithTimer: (NSTimer *)timer
{
    BOOL isDir=NO;
    NSArray *subpaths;
    NSString *exportPath = [self dataDirectory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:exportPath isDirectory:&isDir] && isDir){
        subpaths = [fileManager subpathsAtPath:exportPath];
    }
    NSString *zipFile = [[self zipFileName2: [timer userInfo] ] stringByAppendingString:@".zip"];
    
    NSLog(@"zipFile name = %@", zipFile );
    
    NSString *archivePath = [[self zipDirectory] stringByAppendingString: zipFile ];
    
    ZipArchive *archiver = [[ZipArchive alloc] init];
    [archiver CreateZipFile2:archivePath];
    for(NSString *path in subpaths)
    {
        NSString *longPath = [exportPath stringByAppendingPathComponent:path];
        if([fileManager fileExistsAtPath:longPath isDirectory:&isDir] && !isDir)
        {
            [archiver addFileToZip:longPath newname:path];
        }
    }
    BOOL successCompressing = [archiver CloseZipFile2];
    if(successCompressing)
    {
        NSLog(@"Zipped Successfully!");
    }
    else
    {
        NSLog(@"Fail");
    }
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate pushOnNetworkStack: zipFile];

    
}

+ (void) writeActivity: (ES_Activity *)activity
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [self writeData: [self arrayFromActivity: activity]];
    
    
    NSLog(@"activity timestamp = %@", activity.timestamp);
    
    NSString *zipFileName = [[NSString stringWithFormat: @"/%0.0f-%@", [activity.timestamp doubleValue], appDelegate.user.uuid ] stringByAppendingString:@".zip"];

    activity.zipFilePath = [[self zipDirectory] stringByAppendingString:zipFileName];
    
    NSLog( @"activity.zipfilepath = %@", activity.zipFilePath);
    
    NSTimer *timer;
    timer = [NSTimer scheduledTimerWithTimeInterval: 2
                                             target: self
                                           selector: @selector(zipFilesWithTimer: )
                                           userInfo: [NSString stringWithFormat:@"%0.0f", [activity.timestamp doubleValue] ]
                                            repeats: NO];

}

+ (void) writeData:(NSArray *)array
{
    NSError * error1 = [NSError new];
    
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: array options:0 error:&error1];

    NSString *filePath = [[self dataDirectory] stringByAppendingString: @"/HF_DUR_DATA.txt"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
    NSLog(@"Path to file: %@", filePath);
    NSLog(@"File exists: %d", fileExists);
    NSLog(@"Is deletable file at path: %d", [fileManager isDeletableFileAtPath:filePath]);
    if (fileExists)
    {
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) NSLog(@"Error: %@", [error localizedDescription]);
    }

    
    BOOL writeFileSuccess = [jsonObject writeToFile: filePath atomically:YES];
    if (writeFileSuccess)
    {
        NSLog(@"Data successfully written to file");
    }
    else
    {
        NSLog(@"Error writing data to file!!");
    }

}

+ (NSArray *) arrayFromActivity: (ES_Activity *)activity
{
    NSArray *objects = [NSArray new];
    
    NSArray *samplesArray = [activity.sensorSamples array];
    
    NSArray *keysArray = [NSArray arrayWithObjects: @"speed", @"lat", @"longitude", @"time", @"gyro_x", @"acc_x", @"gyro_y", @"acc_y", @"gyro_z", @"acc_z", @"mic_peak_db",  @"mic_avg_db", nil ];
    
    for ( ES_SensorSample *s in samplesArray )
    {
        NSDictionary *dict = [s dictionaryWithValuesForKeys: keysArray ];
        NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary: dict];
        
        [mDict setValue: [dict objectForKey: @"longitude"] forKey: @"long"];
        
        [mDict removeObjectForKey: @"longitude"];
        
        objects = [objects arrayByAddingObject: mDict];
    }
    
    return objects;
}

@end
