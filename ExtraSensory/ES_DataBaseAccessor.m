//
//  ES_DataBaseAccessor.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//
//

#import "ES_DataBaseAccessor.h"
#import "ES_AppDelegate.h"
#import "ZipArchive.h"
#import "ES_NetworkAccessor.h"
#import "ES_User.h"
#import "ES_Activity.h"
#import "ES_ActivityStatistic.h"
#import "ES_ActivitiesStrings.h"
#import "ES_UserActivityLabels.h"

@implementation ES_DataBaseAccessor

#define ROOT_DATA_OBJECT @"ES_User"
#define HF_SOUND_FILE_DUR   @"/HF_SOUNDWAVE_DUR"

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
    NSLog(@"[databaseAccessor] creating new activity!");
    return [NSEntityDescription insertNewObjectForEntityForName: @"ES_Activity" inManagedObjectContext:[self context]];
}

+ (void) deleteActivity: (ES_Activity *) activity
{
    NSLog(@"[databaseAccessor] deleting activity at %@", activity.timestamp);
    [[self context] deleteObject:activity];
}

+ (void) setSecondaryActivities:(NSArray*)labels forActivity: (ES_Activity *)activity
{
    NSSet *oldlabels = activity.userActivityLabels;
    
    if ([oldlabels count] > 0)
    {
        [activity removeUserActivityLabels:oldlabels];
    }
    
    NSMutableSet *newlabels = [NSMutableSet new];
    
    for (NSString* label in labels)
    {
        ES_UserActivityLabels* newlabel = [self getUserActivityLabelWithName:label];
        [newlabels addObject:newlabel];
    }
    [activity addUserActivityLabels:newlabels];
    
}

+ (ES_UserActivityLabels*) getUserActivityLabelWithName:(NSString*)label
{
    NSError *error = [NSError new];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_UserActivityLabels"];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name = %@", label]];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    if ([results count] > 0)
    {
        return [results firstObject];
    }
    // if not exists, just insert a new entity
    else
    {
        ES_UserActivityLabels *userActivity = [NSEntityDescription insertNewObjectForEntityForName:@"ES_UserActivityLabels"
                                                                                inManagedObjectContext:[self context]];
        userActivity.name = label;
        return userActivity;
    }
}

+ (ES_Activity *) getActivityWithTime: (NSNumber *)time
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat: @"(timestamp = %@)", time ]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    if ([results count])
    {
        return [results firstObject];
    }
    else return nil;
}

+ (ES_Activity *) getMostRecentActivity
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:10];
    NSNumber *past = [NSNumber numberWithInt:(int)[NSDate dateWithTimeIntervalSinceNow:-5*60]]; //in seconds
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", past]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
        
    NSLog(@"number of matching hits = %lu", (unsigned long)[results count]);
    for (ES_Activity *activity in results)
    {
        if (activity.serverPrediction || activity.userCorrection)
        {
            return activity;
        }
    }
    return nil;
}

+ (NSMutableDictionary *) getTodaysCounts
{
    NSArray *mainActivities = [ES_ActivitiesStrings mainActivities];
    NSMutableDictionary *counts = [NSMutableDictionary new];
    for (NSString *act in mainActivities)
    {
        [counts setObject:[NSNumber numberWithInt:0] forKey:act];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:0];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDateComponents *comps = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                     fromDate:date];
    NSDate *today = [cal dateFromComponents:comps];
    NSNumber *todayNum = [NSNumber numberWithInt:(int)today];
    
    //NSNumber *yesterday = [NSNumber numberWithInt:(int)[NSDate dateWithTimeIntervalSinceNow:-24*60*60]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", todayNum]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    for (ES_Activity *activity in results)
    {
        if (activity.userCorrection)
        {
            //count the userCorrection if there is one
            int newCount = (int)[counts[activity.userCorrection] integerValue] + 1;
            counts[activity.userCorrection]  = [NSNumber numberWithInt:newCount];
        }
        else if (activity.serverPrediction)
        {
            //otherwise count the serverPrediction
            int newCount = (int)[counts[activity.serverPrediction] integerValue] + 1;
            counts[activity.serverPrediction]  = [NSNumber numberWithInt:newCount];
        }
    }
    //NSLog(@"Today's counts: %@", counts);
    return counts;
}

+ (NSMutableDictionary *) getTodaysCountsForSecondaryActivities:(NSArray *)secondaryActivities
{
    NSMutableDictionary *counts = [NSMutableDictionary new];
    for (NSString *act in secondaryActivities)
    {
        [counts setObject:[NSNumber numberWithInt:0] forKey:act];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:0];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDateComponents *comps = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                     fromDate:date];
    NSDate *today = [cal dateFromComponents:comps];
    NSNumber *todayNum = [NSNumber numberWithInt:(int)today];
    
    //NSNumber *yesterday = [NSNumber numberWithInt:(int)[NSDate dateWithTimeIntervalSinceNow:-24*60*60]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@ AND userActivityLabel != nil", todayNum]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    for (ES_Activity *activity in results)
    {
        if (activity.userActivityLabels)
        {
            //count the userCorrection if there is one
            int newCount = (int)[counts[activity.userCorrection] integerValue] + 1;
            counts[activity.userCorrection]  = [NSNumber numberWithInt:newCount];
        }
    }
    //NSLog(@"Today's counts: %@", counts);
    return counts;
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

+ (NSString *) zipFileName2: (NSNumber *)time
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    //NSLog(@"time for zip name = %0.0f", [time doubleValue] );
    //[NSString stringWithFormat:@"%0.0f", [time doubleValue]]
    return [NSString stringWithFormat:@"/%0.0f-%@.zip", [time doubleValue], appDelegate.user.uuid];
}


+ (void) zipFilesWithTimer: (NSTimer *)timer
{
    BOOL isDir=NO;
    NSArray *subpaths;
    NSString *exportPath = [self dataDirectory];
    // add audio file to this dataDirectory
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:exportPath isDirectory:&isDir] && isDir){
        subpaths = [fileManager subpathsAtPath:exportPath];
    }
    
    NSString *zipFile = [timer userInfo];
    
    NSString *archivePath = [[self zipDirectory] stringByAppendingString: zipFile ];
    
    ZipArchive *archiver = [[ZipArchive alloc] init];
    [archiver CreateZipFile2:archivePath];
    for(NSString *path in subpaths)
    {
        NSLog(@"path in subpath: %@", path);
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
    [appDelegate.networkAccessor upload]; //upload the new file
}

+ (void) writeActivity: (ES_Activity *)activity
{
    //[self writeData: [self arrayFromActivity: activity]];
    NSLog(@"activity labels: %@", activity.userCorrection);
    if (activity.userCorrection)
    {
        [self writeLabels: activity];
    }
    
    NSString *zipFileName = [self zipFileName2: activity.timestamp];
    //activity.zipFilePath = [[self zipDirectory] stringByAppendingString:zipFileName ];

    NSTimer *timer;
    timer = [NSTimer scheduledTimerWithTimeInterval: 2
                                             target: self
                                           selector: @selector(zipFilesWithTimer: )
                                           userInfo: zipFileName
                                            repeats: NO];

}

+ (void) writeData2:(NSArray *)array
{
    //old version, use writeData:
    NSError * error1 = [NSError new];
    
    NSURL *soundFileURLDur;
    
    NSData *soundData;
    
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: array options:0 error:&error1];

    NSString *filePath = [[self dataDirectory] stringByAppendingString: @"/HF_DUR_DATA.txt"];
    
    // path to which sound file will be saved to along with the other data sensors
    NSString *soundFileStringPath = [[self dataDirectory] stringByAppendingString:HF_SOUND_FILE_DUR];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *dataPath = [fileManager URLForDirectory: NSDocumentDirectory
                                          inDomain: NSUserDomainMask
                                 appropriateForURL: nil
                                            create: YES
                                             error: nil];
    
    // grab the sound file url path which was created in sensor manager
    soundFileURLDur = [NSURL fileURLWithPath:[[dataPath path] stringByAppendingPathComponent:HF_SOUND_FILE_DUR]];
    
    // write contents of url to data object
    soundData = [NSData dataWithContentsOfURL: soundFileURLDur];
    
    //NSLog(@"soundFileURLDur is %@", soundFileURLDur);
 
    NSError *error;
    
    // deleting any old contents in sound file path
    BOOL soundFileExists = [fileManager fileExistsAtPath:soundFileStringPath];
    //NSLog(@"Path to sound file: %@", soundFileStringPath);
    //NSLog(@"Sound File exists: %d", soundFileExists);
    //NSLog(@"Is deletable sound file at path: %d", [fileManager isDeletableFileAtPath:soundFileStringPath]);
    
    if(soundFileExists)
    {
        //NSLog(@"previous sound file existed there");
        BOOL success = [fileManager removeItemAtPath:soundFileStringPath error:&error];
        if (!success) NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    BOOL writeSoundFileSuccess = [soundData writeToFile:soundFileStringPath atomically:YES];
    
    if (writeSoundFileSuccess)
    {
        NSLog(@"Sound file successfully written to new url");
    }
    else
    {
        NSLog(@"Error writing sound data to file!!");
    }
    
    // deleting any old contents in sensor data path
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
    //NSLog(@"Path to file: %@", filePath);
    //NSLog(@"File exists: %d", fileExists);
    //NSLog(@"Is deletable file at path: %d", [fileManager isDeletableFileAtPath:filePath]);
    
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

+ (void) writeData:(NSArray *)array
{
    NSError *error = [NSError new];
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: array options:0 error:&error];
    NSString *filePath = [[self dataDirectory] stringByAppendingString: @"/HF_DUR_DATA.txt"];
    
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

+ (void) clearHFDataFile
{
    NSError *error = [NSError new];
    NSString *filePath = [[self dataDirectory] stringByAppendingString: @"/HF_DUR_DATA.txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!success) NSLog(@"Error: %@", [error localizedDescription]);
    }
}

+ (void) clearLabelFile
{
    NSError *error = [NSError new];
    NSString *filePath = [[self dataDirectory] stringByAppendingString: @"/label.txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!success) NSLog(@"Error: %@", [error localizedDescription]);
    }
}

+ (void) writeLabels:(ES_Activity*)activity
{
    NSError *error = [NSError new];
    
    NSMutableArray* keys = [NSMutableArray arrayWithArray:@[@"mainActivity"]];
    NSMutableArray* values = [NSMutableArray arrayWithArray:@[activity.userCorrection]];
    
    if (activity.userActivityLabels)
    {
        NSMutableArray *secondaryLabels = [NSMutableArray new];
        for (ES_UserActivityLabels* label in activity.userActivityLabels)
        {
            [secondaryLabels addObject:label.name];
        }
        [keys addObject:@"secondaryActivities"];
        [values addObject:secondaryLabels];
    }
    if (activity.mood)
    {
        [keys addObject:@"mood"];
        [values addObject:activity.mood];
    }
    
    NSDictionary *feedback = [[NSDictionary alloc] initWithObjects: values
                                                           forKeys: keys];
    
    NSLog(@"feedback dictionary: %@", feedback);
    
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: feedback options:0 error:&error];
    NSString *filePath = [[self dataDirectory] stringByAppendingString: @"/label.txt"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
    if (fileExists)
    {
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) NSLog(@"Error: %@", [error localizedDescription]);
    }
    BOOL writeFileSuccess = [jsonObject writeToFile: filePath atomically:YES];
    if (writeFileSuccess)
    {
        NSLog(@"Label successfully written to file");
    }
    else
    {
        NSLog(@"Error writing label to file!!");
    }
    
}


//+ (NSArray *) arrayFromActivity: (ES_Activity *)activity
//{
//    NSArray *objects = [NSArray new];
//    
//    NSArray *samplesArray = [activity.sensorSamples array];
//    
//    NSArray *keysArray = [NSArray arrayWithObjects: @"speed", @"lat", @"longitude", @"time", @"gyro_x", @"acc_x", @"gyro_y", @"acc_y", @"gyro_z", @"acc_z", @"mic_peak_db",  @"mic_avg_db", nil ];
//    
//    for ( ES_SensorSample *s in samplesArray )
//    {
//        NSDictionary *dict = [s dictionaryWithValuesForKeys: keysArray ];
//        NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary: dict];
//        
//        [mDict setValue: [dict objectForKey: @"longitude"] forKey: @"long"];
//        
//        [mDict removeObjectForKey: @"longitude"];
//        
//        objects = [objects arrayByAddingObject: mDict];
//    }
//    
//    return objects;
//}

@end
