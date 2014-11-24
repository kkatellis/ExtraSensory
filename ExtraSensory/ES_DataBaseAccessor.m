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
#define HF_SOUND_FILE_DUR   @"HF_SOUNDWAVE_DUR"
#define MFCC_FILE_DUR   @"MFCC_SOUNDWAVE_DUR"
#define HF_DATA_FILE_DUR    @"HF_DUR_DATA.txt"
#define LABEL_FILE          @"label.txt"

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
        NSLog(@"[databaseAccessor] Initializing user for the first time!");
        user = [NSEntityDescription insertNewObjectForEntityForName: ROOT_DATA_OBJECT inManagedObjectContext: [self context]];
        user.settings = [NSEntityDescription insertNewObjectForEntityForName: @"ES_Settings" inManagedObjectContext:[self context]];
        user.activityStatistics = [NSEntityDescription insertNewObjectForEntityForName:@"ES_ActivityStatistics" inManagedObjectContext:[self context]];
        user.uuid = [[NSUUID UUID] UUIDString];
        user.activityStatistics.timeSamplingBegan = [NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]];
        [self save];
    }
    else if ([users count] == 1)
    {
        NSLog(@"[databaseAccessor] Getting user from database");
        user = [users objectAtIndex: 0];
    }
    else
    {
        NSLog( @"[databaseAccessor] !!! Why are there %lu users in the database??", (unsigned long)[users count] );
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
    id actObj = [NSEntityDescription insertNewObjectForEntityForName: @"ES_Activity" inManagedObjectContext:[self context]];
    ES_Activity *act = (ES_Activity *)actObj;
    act.user = [self user];
    act.uuid = act.user.uuid;
    NSLog(@"[databaseAccessor] Created new activity with uuid: %@.",act.user.uuid);
    
    return act;
}

+ (BOOL) isActivityOrphanAndNowDeletedActivity:(ES_Activity *)activity
{
    if (activity.serverPrediction)
    {
        // Then this activity's measurements were received by the server
        return NO;
    }
    
    if (!activity.timestamp)
    {
        // Then this might be just created now
        return NO;
    }
    
    if ([activity.timestamp doubleValue] > ([[NSDate date] timeIntervalSince1970] - 60) )
    {
        // This activity is very recent, and might still be in the process of acquiring data measurements
        return NO;
    }
    
    // Check if there is a zip file for this activity:
    NSString *zipFile = [NSString stringWithFormat:@"%@%@",[self zipDirectory],[self zipFileName:activity.timestamp]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:zipFile])
    {
        // Then this activity's data may still be sent to the server
        return NO;
    }
    
    // If reached here, this activity is an 'orphan' - it has no server prediction and no measurement data on the phone, so probably is not associated with any measurement data either on the phone or on the server. Hence, it is useless and should be deleted:
    NSLog(@"[databaseAccessor] Orphan activity for time %@ (timestamp %@) should be deleted",[[NSDate dateWithTimeIntervalSince1970:[activity.timestamp doubleValue]] descriptionWithLocale:[NSLocale currentLocale]],activity.timestamp);
    [self deleteActivity:activity];
    return YES;
}

+ (void) deleteActivity: (ES_Activity *) activity
{
    NSLog(@"[databaseAccessor] Deleting activity at %@", activity.timestamp);
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
        
    for (ES_Activity *activity in results)
    {
        if (activity.serverPrediction || activity.userCorrection)
        {
            return activity;
        }
    }
    return nil;
}

+ (NSNumber *) getTimestampOfTodaysStart
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDateComponents *comps = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                     fromDate:date];
    NSDate *today = [cal dateFromComponents:comps];
    NSNumber *todayNum = [NSNumber numberWithFloat:[today timeIntervalSince1970]];
    
    return todayNum;
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
    
    NSNumber *todayNum = [self getTimestampOfTodaysStart];
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

/*
 * Check the recent period of time and return the latest activity that already has a user correction, or nil, if no such activity was found in the defined recent period.
 */
+ (ES_Activity *) getLatestCorrectedActivityWithinTheLatest:(NSNumber *)seconds
{
    float secondsFloat = [seconds floatValue];
    NSTimeInterval secondsInterval = -secondsFloat;
    NSDate *sinceTime = [NSDate dateWithTimeIntervalSinceNow:secondsInterval];
    NSNumber *since = [NSNumber numberWithFloat:[sinceTime timeIntervalSince1970]];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:0];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K > %@",@"timestamp",since]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    // Go over the activities (from latest to earliest):
    for (ES_Activity *activity in results)
    {
        // Check if this activity already has user-correction:
        if (activity.userCorrection)
        {
            return activity;
        }
    }
        
    return nil;
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
    
    NSNumber *todayNum = [self getTimestampOfTodaysStart];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K > %@ AND %K.@count > 0", @"timestamp",todayNum,@"userActivityLabels"]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    for (ES_Activity *activity in results)
    {
        if (activity.userActivityLabels)
        {
            for (id actObj in activity.userActivityLabels)
            {
                NSString *activityName = [(ES_UserActivityLabels *)actObj name];
                int newCount = (int)[counts[activityName] integerValue] + 1;
                counts[activityName] = [NSNumber numberWithInt:newCount];
            }
        }
        else
        {
            NSLog(@"[databaseAccessor] fetch gave result with nil userActivityLabels");
        }
    }
    //NSLog(@"Today's counts: %@", counts);
    return counts;
}

+ (NSMutableDictionary *) getTodaysCountsForMoods:(NSArray *)moods
{
    NSMutableDictionary *counts = [NSMutableDictionary new];
    for (NSString *mood in moods)
    {
        [counts setObject:[NSNumber numberWithInt:0] forKey:mood];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:0];
    
    NSNumber *todayNum = [self getTimestampOfTodaysStart];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K > %@", @"timestamp",todayNum]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    for (ES_Activity *activity in results)
    {
        if (activity.mood)
        {
            int newCount = (int)[counts[activity.mood] integerValue] + 1;
            counts[activity.mood] = [NSNumber numberWithInt:newCount];
        }
        else
        {
            NSLog(@"[databaseAccessor] fetch gave result with nil mood");
        }
    }
    return counts;
}

+ (NSArray *) getFrequentLabelsOutOfLabelsWithCounts:(NSDictionary *)counts
{
    NSMutableDictionary *nonzeroCounts = [NSMutableDictionary dictionary];
    for (NSString *label in [counts allKeys])
    {
        if ([counts[label] intValue] > 0)
        {
            [nonzeroCounts setObject:counts[label] forKey:label];
        }
    }
    
    NSArray *labelsByFrequency = [nonzeroCounts keysSortedByValueUsingComparator:^(NSNumber *num1,NSNumber *num2)
    {
        if ([num1 intValue] > [num2 intValue])
            return NSOrderedAscending;
        if ([num1 intValue] < [num2 intValue])
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    return labelsByFrequency;
}

+ (NSArray *) getTodaysFrequentSecondaryActivitiesOutOf:(NSArray *)secondaryActivities
{
    NSDictionary *counts = [self getTodaysCountsForSecondaryActivities:secondaryActivities];
    NSArray *secondaryActivitiesByFrequency = [self getFrequentLabelsOutOfLabelsWithCounts:counts];
    return secondaryActivitiesByFrequency;
}

+ (NSArray *) getTodaysFrequentMoodsOutOf:(NSArray *)moods
{
    NSDictionary *counts = [self getTodaysCountsForMoods:moods];
    NSArray *moodsByFrequency = [self getFrequentLabelsOutOfLabelsWithCounts:counts];
    return moodsByFrequency;
}

+ (void) save
{
    NSError *error = [[NSError alloc] init];
    
    if ([[self context] save:&error])
    {
        NSLog(@"[databaseAccessor] Saved DB.");
    }
    else
    {
        NSLog(@"[databaseAccessor] !!! %@", [error localizedDescription]);
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
            NSLog(@"[databaseAccessor] !!! Failed to create directory \"%@\". Error: %@", directory, error);
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
            NSLog(@"[databaseAccessor] !!! Failed to create directory \"%@\". Error: %@", directory, error);
        }
    }
    return directory;
}

+ (NSString *) zipFileName: (NSNumber *)time
{
    ES_AppDelegate *appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    return [NSString stringWithFormat:@"/%0.0f-%@.zip", [time doubleValue], appDelegate.user.uuid];
}

+ (NSArray *) filesToPackInsizeZipFile
{
    NSArray *arr = [NSArray arrayWithObjects:HF_DATA_FILE_DUR,LABEL_FILE,HF_SOUND_FILE_DUR,MFCC_FILE_DUR, nil];
//    NSArray *arr = [NSArray arrayWithObjects:HF_DATA_FILE_DUR,LABEL_FILE, nil];
    
    return arr;
}

+ (void) zipFilesWithTimer: (NSTimer *)timer
{
    BOOL isDir=NO;
    NSString *dataPath = [self dataDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *filenames = [self filesToPackInsizeZipFile];
//    if ([fileManager fileExistsAtPath:dataPath isDirectory:&isDir] && isDir){
//        filenames = [fileManager subpathsAtPath:dataPath];
//    }
    
    NSString *zipFilename = [timer userInfo];
    NSString *archivePath = [[self zipDirectory] stringByAppendingString: zipFilename ];
    
    ZipArchive *archiver = [[ZipArchive alloc] init];
    [archiver CreateZipFile2:archivePath];
    for(NSString *filename in filenames)
    {
        NSLog(@"[databaseAccessor] File to add to zip: %@", filename);
        NSString *fileFullPath = [NSString stringWithFormat:@"%@/%@",dataPath,filename];
        if([fileManager fileExistsAtPath:fileFullPath isDirectory:&isDir] && !isDir)
        {
            [archiver addFileToZip:fileFullPath newname:filename];
        }
    }
    BOOL successCompressing = [archiver CloseZipFile2];
    if(successCompressing)
    {
        NSLog(@"[databaseAccessor] Zipped Successfully!");
    }
    else
    {
        NSLog(@"[databaseAccessor] !!! Zip failed.");
    }
    ES_AppDelegate *appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate pushOnNetworkStack: zipFilename];
    [appDelegate.networkAccessor upload]; //upload the new file
}

+ (void) writeActivity: (ES_Activity *)activity
{
    //[self writeData: [self arrayFromActivity: activity]];
    NSLog(@"[databaseAccessor] Writing activity label: %@", activity.userCorrection);
    if (activity.userCorrection)
    {
        [self writeLabels: activity];
    }
    
    NSString *zipFileName = [self zipFileName: activity.timestamp];

    NSTimer *timer;
    timer = [NSTimer scheduledTimerWithTimeInterval: 2
                                             target: self
                                           selector: @selector(zipFilesWithTimer: )
                                           userInfo: zipFileName
                                            repeats: NO];

}

//+ (void) writeData2:(NSArray *)array
//{
//    //old version, use writeData:
//    NSError * error1 = [NSError new];
//    
//    NSURL *soundFileURLDur;
//    
//    NSData *soundData;
//    
//    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: array options:0 error:&error1];
//
//    NSString *filePath = [[self dataDirectory] stringByAppendingString: HF_DATA_FILE_DUR];
//    
//    // path to which sound file will be saved to along with the other data sensors
//    NSString *soundFileStringPath = [[self dataDirectory] stringByAppendingString:HF_SOUND_FILE_DUR];
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    
//    NSURL *dataPath = [fileManager URLForDirectory: NSDocumentDirectory
//                                          inDomain: NSUserDomainMask
//                                 appropriateForURL: nil
//                                            create: YES
//                                             error: nil];
//    
//    // grab the sound file url path which was created in sensor manager
//    soundFileURLDur = [NSURL fileURLWithPath:[[dataPath path] stringByAppendingPathComponent:HF_SOUND_FILE_DUR]];
//    
//    // write contents of url to data object
//    soundData = [NSData dataWithContentsOfURL: soundFileURLDur];
//    
//    //NSLog(@"soundFileURLDur is %@", soundFileURLDur);
// 
//    NSError *error;
//    
//    // deleting any old contents in sound file path
//    BOOL soundFileExists = [fileManager fileExistsAtPath:soundFileStringPath];
//    //NSLog(@"Path to sound file: %@", soundFileStringPath);
//    //NSLog(@"Sound File exists: %d", soundFileExists);
//    //NSLog(@"Is deletable sound file at path: %d", [fileManager isDeletableFileAtPath:soundFileStringPath]);
//    
//    if(soundFileExists)
//    {
//        //NSLog(@"previous sound file existed there");
//        BOOL success = [fileManager removeItemAtPath:soundFileStringPath error:&error];
//        if (!success) NSLog(@"[databaseAccessor] !!! Error: %@", [error localizedDescription]);
//    }
//    
//    BOOL writeSoundFileSuccess = [soundData writeToFile:soundFileStringPath atomically:YES];
//    
//    if (writeSoundFileSuccess)
//    {
//        NSLog(@"[databaseAccessor] Sound file successfully written to new url");
//    }
//    else
//    {
//        NSLog(@"[databaseAccessor] !!! Error writing sound data to file!!");
//    }
//    
//    // deleting any old contents in sensor data path
//    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
//    //NSLog(@"Path to file: %@", filePath);
//    //NSLog(@"File exists: %d", fileExists);
//    //NSLog(@"Is deletable file at path: %d", [fileManager isDeletableFileAtPath:filePath]);
//    
//    if (fileExists)
//    {
//        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
//        if (!success) NSLog(@"[databaseAccessor] !!! Error: %@", [error localizedDescription]);
//    }
//
//    
//    BOOL writeFileSuccess = [jsonObject writeToFile: filePath atomically:YES];
//    if (writeFileSuccess)
//    {
//        NSLog(@"[databaseAccessor] Data successfully written to file");
//    }
//    else
//    {
//        NSLog(@"[databaseAccessor] !!! Error writing data to file!!");
//    }
//
//}

+ (NSString *) HFDataFileFullPath
{
    return [NSString stringWithFormat:@"%@/%@",[self dataDirectory],HF_DATA_FILE_DUR];
}

+ (NSString *) labelFileFullPath
{
    return [NSString stringWithFormat:@"%@/%@",[self dataDirectory],LABEL_FILE];
}

+ (NSString *) soundFileFullPath
{
    return [NSString stringWithFormat:@"%@/%@",[self dataDirectory],HF_SOUND_FILE_DUR];
}

+ (void) writeData:(NSArray *)array
{
    NSError *error = [NSError new];
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: array options:0 error:&error];
    NSString *filePath = [self HFDataFileFullPath];
    
    BOOL writeFileSuccess = [jsonObject writeToFile: filePath atomically:YES];
    if (writeFileSuccess)
    {
        NSLog(@"[databaseAccessor] Data successfully written to file");
    }
    else
    {
        NSLog(@"[databaseAccessor] !!! Error writing data to file!!");
    }
}

+ (void) clearDataFile:(NSString *)filePath
{
    NSError *error = [NSError new];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!success) NSLog(@"[databaseAccessor] !!! Error: %@", [error localizedDescription]);
    }
}

+ (void) clearHFDataFile
{
    [self clearDataFile:[self HFDataFileFullPath]];
}

+ (void) clearLabelFile
{
    [self clearDataFile:[self labelFileFullPath]];
}

+ (void) clearSoundFile
{
    [self clearDataFile:[self soundFileFullPath]];
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
    
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: feedback options:0 error:&error];
    NSString *filePath = [self labelFileFullPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
    if (fileExists)
    {
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) NSLog(@"[databaseAccessor] !!! Error: %@", [error localizedDescription]);
    }
    BOOL writeFileSuccess = [jsonObject writeToFile: filePath atomically:YES];
    if (writeFileSuccess)
    {
        NSLog(@"[databaseAccessor] Label successfully written to file");
    }
    else
    {
        NSLog(@"[databaseAccessor] !!! Error writing label to file!!");
    }
    
}

+ (NSArray *) getActivitiesFrom:(NSNumber *)startTimestamp to:(NSNumber *)endTimestamp
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:0];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K > %@ AND %K < %@",@"timestamp",startTimestamp,@"timestamp",endTimestamp]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]];
     
     NSError *error = [NSError new];
     NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    return results;
}

+ (NSArray *) getWhileDeletingOrphansActivitiesFrom:(NSNumber *)startTimestamp to:(NSNumber *)endTimestamp
{
    NSArray *activities = [self getActivitiesFrom:startTimestamp to:endTimestamp];
    NSMutableArray *livingActivities = [NSMutableArray arrayWithCapacity:activities.count];
    
    for (ES_Activity *activity in activities)
    {
        if (![self isActivityOrphanAndNowDeletedActivity:activity])
        {
            // Then this is a live activity, add it:
            [livingActivities addObject:activity];
        }
    }
    
    return livingActivities;
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
