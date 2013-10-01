//
//  ES_DataBaseAccessor.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_DataBaseAccessor.h"
#import "ES_AppDelegate.h"
#import "ES_Sample.h"
#import "ZipArchive.h"
#import "ES_NetworkAccessor.h"
#import "ES_SettingsModel.h"

@implementation ES_DataBaseAccessor

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

+ (ES_Sample *) write
{
    return [NSEntityDescription insertNewObjectForEntityForName: @"ES_Sample" inManagedObjectContext: [self context]];
}

+ (void) save
{
    NSError *error = [[NSError alloc] init];
    
    if (![[self context] save:&error])
    {
        NSLog(@"Error saving sample data!");
    }
}

+ (ES_SettingsModel *) newSettingsModel
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"ES_SettingsModel"
                                         inManagedObjectContext:[self context]];
}

+ (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (void) zipData
{
    NSLog( @"Writing File");
    
    NSString *zipName = [self zipFilesInDirectory:[self dataDirectory]];
    
    
    
    if (zipName)
    {
        NSLog( @"Pushing: %@", zipName);
        ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate pushOnNetworkStack: zipName];
    }
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

+ (NSString *) serverResponseDirectory
{
    NSString *directory = [[self applicationDocumentsDirectory] stringByAppendingString: @"/serverResponse"];
    
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

+ (NSString *) zipFileName
{
    NSDate *now = [NSDate date];
    NSTimeInterval timestamp = [now timeIntervalSince1970];
    
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSString *uuid = [appDelegate.uuid UUIDString];
    
    return [NSString stringWithFormat:@"/%0.0f-%@", timestamp, uuid];
}

+ (NSString *) zipFilesInDirectory: (NSString *)dirToZip
{
    
    BOOL isDir=NO;
    NSArray *subpaths;
    NSString *exportPath = dirToZip;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:exportPath isDirectory:&isDir] && isDir){
        subpaths = [fileManager subpathsAtPath:exportPath];
    }
    NSString *zipFile = [[self zipFileName] stringByAppendingString:@".zip"];
    
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
        return zipFile;
    }
    else
    {
        NSLog(@"Fail");
        return nil;
    }
    
}

@end
