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
//#import "ES_UserActivityLabels.h"
#import "ES_Label.h"
#import "ES_SecondaryActivity.h"
#import "ES_Mood.h"

@implementation ES_DataBaseAccessor

#define ROOT_DATA_OBJECT @"ES_User"
#define HF_SOUND_FILE_DUR   @"HF_SOUNDWAVE_DUR"
#define MFCC_FILE_DUR       @"sound.mfcc"
#define AUDIO_PROP_FILE     @"m_audio_properties.json"
#define HF_DATA_FILE_DUR    @"HF_DUR_DATA.txt"
#define LABEL_FILE          @"label.txt"

#define SECONDS_IN_WEEK     604800.0


+ (NSString *)getMFCCFilename
{
    return MFCC_FILE_DUR;
}

+ (NSString *)getHFDataFilename
{
    return HF_DATA_FILE_DUR;
}

+ (NSString *)getAudioPropertiesFilename
{
    return AUDIO_PROP_FILE;
}

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
    act.labelSource = [NSNumber numberWithInteger:ES_LabelSourceDefault];

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
        NSLog(@"====== still holding zip file %@, so activity is not orphan",zipFile);
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

//+ (void) setSecondaryActivities:(NSArray*)labels forActivity: (ES_Activity *)activity
//{
//    NSSet *oldlabels = activity.userActivityLabels;
//    
//    if ([oldlabels count] > 0)
//    {
//        [activity removeUserActivityLabels:oldlabels];
//    }
//    
//    NSMutableSet *newlabels = [NSMutableSet new];
//    
//    for (NSString* label in labels)
//    {
//        ES_UserActivityLabels* newlabel = [self getUserActivityLabelWithName:label];
//        [newlabels addObject:newlabel];
//    }
//    [activity addUserActivityLabels:newlabels];
//    
//}
//

+ (void) setMoods:(NSArray *)labels forActivity:(ES_Activity *)activity
{
    NSSet *oldLabels = activity.moods;
    
    if ([oldLabels count] > 0)
    {
        [activity removeMoods:oldLabels];
    }
    
    NSMutableSet *newLabels = [NSMutableSet new];
    for (NSString *label in labels)
    {
        ES_Mood *newLabel = [self getMoodEntityWithName:label];
        [newLabels addObject:newLabel];
    }
    [activity addMoods:newLabels];
}

+ (void) setSecondaryActivities:(NSArray*)labels forActivity: (ES_Activity *)activity
{
    NSSet *oldLabels = activity.secondaryActivities;
    
    if ([oldLabels count] > 0)
    {
        [activity removeSecondaryActivities:oldLabels];
    }
    
    NSMutableSet *newLabels = [NSMutableSet new];
    
    for (NSString* label in labels)
    {
        ES_SecondaryActivity* newlabel = [self getSecondaryActivityEntityWithName:label];
        [newLabels addObject:newlabel];
    }
    [activity addSecondaryActivities:newLabels];
    
}

+ (ES_SecondaryActivity *) getSecondaryActivityEntityWithName:(NSString *)label
{
    NSError *error = [NSError new];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_SecondaryActivity"];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"label = %@", label]];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    if ([results count] > 0)
    {
        return [results firstObject];
    }
    // if not exists, just insert a new entity
    else
    {
        ES_SecondaryActivity *secondaryActivity = [NSEntityDescription insertNewObjectForEntityForName:@"ES_SecondaryActivity"
                                                                            inManagedObjectContext:[self context]];
        secondaryActivity.label = label;
        return secondaryActivity;
    }

}

+ (ES_Mood *) getMoodEntityWithName:(NSString *)label
{
    NSError *error = [NSError new];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Mood"];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"label = %@", label]];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    if ([results count] > 0)
    {
        return [results firstObject];
    }
    // if not exists, just insert a new entity
    else
    {
        ES_Mood *mood = [NSEntityDescription insertNewObjectForEntityForName:@"ES_Mood"
                                                                                inManagedObjectContext:[self context]];
        mood.label = label;
        return mood;
    }
    
}

//+ (ES_UserActivityLabels*) getUserActivityLabelWithName:(NSString*)label
//{
//    NSError *error = [NSError new];
//    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_UserActivityLabels"];
//    [fetchRequest setFetchLimit:1];
//    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name = %@", label]];
//    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
//    
//    if ([results count] > 0)
//    {
//        return [results firstObject];
//    }
//    // if not exists, just insert a new entity
//    else
//    {
//        ES_UserActivityLabels *userActivity = [NSEntityDescription insertNewObjectForEntityForName:@"ES_UserActivityLabels"
//                                                                                inManagedObjectContext:[self context]];
//        
//        userActivity.name = label;
//        return userActivity;
//    }
//}

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
    NSNumber *todayNum = [NSNumber numberWithDouble:[today timeIntervalSince1970]];
    
    return todayNum;
}

+ (NSInteger) howManyUnlabeledActivitiesToday
{
    NSNumber *todayNum = [self getTimestampOfTodaysStart];
    NSNumber *now = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSArray *todaysActivities = [self getActivitiesFrom:todayNum to:now];
    
    NSInteger numUnlabeled = 0;
    for (ES_Activity *act in todaysActivities)
    {
        if (!act.userCorrection)
        {
            numUnlabeled ++;
        }
    }
    
    return numUnlabeled;
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

+ (NSMutableDictionary *) getRecentCountsForSecondaryActivities:(NSArray *)secondaryActivities
{
    NSMutableDictionary *counts = [NSMutableDictionary new];
    for (NSString *act in secondaryActivities)
    {
        [counts setObject:[NSNumber numberWithInt:0] forKey:act];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:0];
    
    float startFrom = [[NSDate date] timeIntervalSince1970] - SECONDS_IN_WEEK;
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K > %f AND %K.@count > 0", @"timestamp",startFrom,@"secondaryActivities"]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    for (ES_Activity *activity in results)
    {
        if (activity.secondaryActivities)
        {
            for (id actObj in activity.secondaryActivities)
            {
                NSString *activityName = [(ES_SecondaryActivity *)actObj label];
                int newCount = (int)[counts[activityName] integerValue] + 1;
                counts[activityName] = [NSNumber numberWithInt:newCount];
            }
        }
    }
    //NSLog(@"Today's counts: %@", counts);
    return counts;
}

+ (NSMutableDictionary *) getRecentCountsForMoods:(NSArray *)moods
{
    NSMutableDictionary *counts = [NSMutableDictionary new];
    for (NSString *mood in moods)
    {
        [counts setObject:[NSNumber numberWithInt:0] forKey:mood];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    [fetchRequest setFetchLimit:0];
    
    float startFrom = [[NSDate date] timeIntervalSince1970] - SECONDS_IN_WEEK;
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K > %f AND %K.@count > 0", @"timestamp",startFrom,@"moods"]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    NSError *error = [NSError new];
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    for (ES_Activity *activity in results)
    {
        if (activity.moods)
        {
            for (id moodObj in activity.moods)
            {
                NSString *moodName = [(ES_Mood *)moodObj label];
                int newCount = (int)[counts[moodName] integerValue] + 1;
                counts[moodName] = [NSNumber numberWithInt:newCount];
            }
        }
    }
    //NSLog(@"Today's counts: %@", counts);
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

+ (NSArray *) getRecentFrequentSecondaryActivitiesOutOf:(NSArray *)secondaryActivities
{
    NSDictionary *counts = [self getRecentCountsForSecondaryActivities:secondaryActivities];
    NSArray *secondaryActivitiesByFrequency = [self getFrequentLabelsOutOfLabelsWithCounts:counts];
    return secondaryActivitiesByFrequency;
}

+ (NSArray *) getRecentFrequentMoodsOutOf:(NSArray *)moods
{
    NSDictionary *counts = [self getRecentCountsForMoods:moods];
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

+ (NSString *) feedbackDirectory
{
    NSString *directory = [[self applicationDocumentsDirectory] stringByAppendingString: @"/feedback"];
    
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
    NSArray *arr = [NSArray arrayWithObjects:[self getHFDataFilename],LABEL_FILE,[self getMFCCFilename],[self getAudioPropertiesFilename], nil];
    
    return arr;
}

+ (void) zipFilesWithZipFilename:(NSString *)zipFilename
{
    BOOL isDir=NO;
    NSString *dataPath = [self dataDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *filenames = [self filesToPackInsizeZipFile];
    
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

+ (void) zipFilesWithTimer: (NSTimer *)timer
{
    NSLog(@"=== in zip files with timer");
    NSString *zipFilename = [timer userInfo];
    [self zipFilesWithZipFilename:zipFilename];
}

+ (void) writeSensorData:(NSDictionary *)data andActivity:(ES_Activity *)activity
{
    [self writeSensorData:data];
    NSLog(@"[databaseAccessor] activity has label: %@",activity.userCorrection);
    if (activity.userCorrection)
    {
        [self writeLabels:activity];
    }
    
    NSString *zipFilename = [self zipFileName:activity.timestamp];
    NSLog(@"=== in write .... zip file: %@",zipFilename);
    [self zipFilesWithZipFilename:zipFilename];
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
    NSLog(@"=== in write activity. should create zip file: %@",zipFileName);

    NSTimer *timer;
    timer = [NSTimer scheduledTimerWithTimeInterval: 2
                                             target: self
                                           selector: @selector(zipFilesWithTimer: )
                                           userInfo: zipFileName
                                            repeats: NO];
    
    
}

+ (NSString *) getDataFileFullPathForFilename:(NSString *)filename
{
    return [NSString stringWithFormat:@"%@/%@",[self dataDirectory],filename];
}


+ (void) writeSensorData:(NSDictionary *)data
{
    if (![NSJSONSerialization isValidJSONObject:data]) {
        NSLog(@"[databaseAccessor] !!! Given sensor data is not valid object for JSON. Data: %@",data);
        return;
    }
    NSError *error = [NSError new];
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    NSString *filePath = [self getDataFileFullPathForFilename:HF_DATA_FILE_DUR];
    
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

+ (void) writeData:(NSArray *)array
{
    NSError *error = [NSError new];
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: array options:0 error:&error];
    NSString *filePath = [self getDataFileFullPathForFilename:HF_DATA_FILE_DUR];
    
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

+ (NSString *) feedbackFileFullPathForTimestamp:(NSNumber *)timestamp {
    NSString *feedbackFileFullPath = [NSString stringWithFormat:@"%@/%@.feedback",[self feedbackDirectory],timestamp];
    return feedbackFileFullPath;
}

+ (void) createFeedbackFile:(NSNumber *)timestamp {
    NSString *content = @" ";
    [[NSFileManager defaultManager] createFileAtPath:[self feedbackFileFullPathForTimestamp:timestamp] contents:[content dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
}

+ (void) clearFeedbackFile:(NSNumber *)timestamp {
    [self clearDataFile:[self feedbackFileFullPathForTimestamp:timestamp]];
}

+ (void) clearDataFiles
{
    for (NSString *filePath in [self filesToPackInsizeZipFile]) {
        [self clearDataFile:filePath];
    }
    [self clearDataFile:[self getDataFileFullPathForFilename:HF_SOUND_FILE_DUR]];
}


+ (void) writeLabels:(ES_Activity*)activity
{
    NSError *error = [NSError new];
    
    NSMutableArray* keys = [NSMutableArray arrayWithArray:@[@"mainActivity"]];
    NSMutableArray* values = [NSMutableArray arrayWithArray:@[activity.userCorrection]];
    
    if (activity.secondaryActivities)
    {
        NSMutableArray *secondaryLabels = [NSMutableArray new];
        for (ES_SecondaryActivity* label in activity.secondaryActivities)
        {
            [secondaryLabels addObject:label.label];
        }
        [keys addObject:@"secondaryActivities"];
        [values addObject:secondaryLabels];
    }
    if (activity.moods)
    {
        NSMutableArray *moodLabels = [NSMutableArray new];
        for (ES_Mood *label in activity.moods)
        {
            [moodLabels addObject:label.label];
        }
        [keys addObject:@"moods"];
        [values addObject:moodLabels];
    }
    
    NSDictionary *feedback = [[NSDictionary alloc] initWithObjects: values
                                                           forKeys: keys];
    
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject: feedback options:0 error:&error];
    NSString *filePath = [self getDataFileFullPathForFilename:LABEL_FILE];
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
