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

+ (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (void) writeToTextFile
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
    
    NSString *archivePath = [[self dataDirectory] stringByAppendingString: zipFile ];
    
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
        NSLog(@"Success: %@", archivePath);
        return zipFile;
    }
    else
    {
        NSLog(@"Fail");
        return nil;
    }
    
}

/*+ (NSData *) compressData: (NSData *) uncompressedData
 {
 NSLog( @"compressData: %@", [uncompressedData description]);
 
 
 if ([uncompressedData length] == 0) return uncompressedData;
 
 z_stream strm;
 
 strm.zalloc = Z_NULL;
 strm.zfree = Z_NULL;
 strm.opaque = Z_NULL;
 strm.total_out = 0;
 strm.next_in=(Bytef *)[uncompressedData bytes];
 strm.avail_in = (unsigned int)[uncompressedData length];
 
 // Compresssion Levels:
 //   Z_NO_COMPRESSION
 //   Z_BEST_SPEED
 //   Z_BEST_COMPRESSION
 //   Z_DEFAULT_COMPRESSION
 
 if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
 
 NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
 
 do {
 
 if (strm.total_out >= [compressed length])
 [compressed increaseLengthBy: 16384];
 
 strm.next_out = [compressed mutableBytes] + strm.total_out;
 strm.avail_out = (unsigned int)([compressed length] - strm.total_out);
 
 deflate(&strm, Z_FINISH);
 
 } while (strm.avail_out == 0);
 deflateEnd(&strm);
 
 [compressed setLength:strm.total_out];
 return [NSData dataWithData: compressed];
 }*/

@end
