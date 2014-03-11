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
#import "ES_SensorSample.h"
#import "ES_UserActivityLabel.h"

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
    return [NSEntityDescription insertNewObjectForEntityForName: @"ES_Activity" inManagedObjectContext:[self context]];
}

+ (void) deleteActivity: (ES_Activity *) activity
{
    NSLog(@"deleting activity at %@", activity.timestamp);
    [[self context] deleteObject:activity];
}

+ (ES_SensorSample *) newSensorSample
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"ES_SensorSample" inManagedObjectContext:[self context]];
}

+ (ES_UserActivityLabel *) getUserActivityLabel: (NSString *)label
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_UserActivityLabel"];
    NSError *error = [NSError new];
    
    if ([[self context] countForFetchRequest:fetchRequest error:&error])
    {
        ES_UserActivityLabel *UserActivityLabel = [[[self context] executeFetchRequest:fetchRequest error:&error] firstObject];
        NSLog(@"found UserActivityLabel: %@", UserActivityLabel.name);
        return UserActivityLabel;
    }
    // if not exists, just insert a new entity
    else
    {
        ES_UserActivityLabel *UserActivityLabel = [NSEntityDescription insertNewObjectForEntityForName:@"ES_UserActivityLabel"
                                              inManagedObjectContext:[self context]];
        UserActivityLabel.name = label;
        NSLog(@"added a new entry for UserActivityLabel: %@", UserActivityLabel.name);
        return UserActivityLabel;
    }
}

+ (void)addUserActivityLabel:(NSString *)label toActivity:(ES_Activity *)activity
{
    ES_UserActivityLabel *UserActivityLabel = [self getUserActivityLabel:label];
    [activity addUserActivityLabelsObject:UserActivityLabel];
}

+ (void)removeUserActivityLabel:(NSString *)label fromActivity:(ES_Activity *)activity
{
    ES_UserActivityLabel *UserActivityLabel = [self getUserActivityLabel:label];
    [activity removeUserActivityLabelsObject:UserActivityLabel];
}

+ (ES_Activity *) getActivityWithTime: (NSNumber *)time
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ES_Activity" inManagedObjectContext:[self context]];
    [fetchRequest setEntity:entity];
        
    //NSLog(@"attributeValue = %@", [NSString stringWithFormat: @"%@", time] );
    
    //NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(timestamp == %@)", attributeValue ];
    
    //[fetchRequest setPredicate:predicate];
    
    NSError *error = [NSError new];
    
    NSArray *results = [[self context] executeFetchRequest:fetchRequest error:&error];
    
    //NSLog(@"nubmer of results = %lu", (unsigned long)[results count]);
    
    ES_Activity *resultActivity;
    
    for (ES_Activity *a in results)
    {
        NSNumber *t = a.timestamp;
        
        //NSLog(@"time = %@, t = %@", time, t );
        
        if ( [t intValue] == [time intValue] ) resultActivity = a;
        
            
    }
    
    
    NSLog(@"number of matching hits = %lu", (unsigned long)[results count]);
   // NSLog(@"error: %@", [error localizedDescription]);
    
    if ([results count] > 0 )
    {
        return resultActivity;
    }
    else return nil;
    
//    for ( id a in results )
//    {
//        NSLog(@"result: %@", a);
//    }
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
        [self writeLabel: activity.userCorrection];
    }
    
    NSString *zipFileName = [self zipFileName2: activity.timestamp];
    activity.zipFilePath = [[self zipDirectory] stringByAppendingString:zipFileName ];

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

+ (void) writeLabel:(NSString *)label
{
    NSError *error = [NSError new];
    NSDictionary *feedback = [[NSDictionary alloc] initWithObjects:@[label] forKeys:@[@"label"]];
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
