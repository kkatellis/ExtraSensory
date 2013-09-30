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
#import "zlib.h"

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
    
    NSString *directory = [self applicationDocumentsDirectory];
    NSString *fullPath = [directory stringByAppendingString: @"/testTextFile.txt"];
    NSError *error = [NSError new];
    
    
    [@"testString" writeToFile:fullPath atomically:YES encoding: NSUTF8StringEncoding error:&error ];
    
    [self zip];
}

+ (void) zip
{
    NSLog( @"zipping File");
    
    NSString *directory = [self applicationDocumentsDirectory];
    NSString *fullPath = [directory stringByAppendingString: @"/testTextFile.txt"];
    
    NSString *zipPath = [directory stringByAppendingString: @"/testZip.zip"];
    
    NSData *uncompressedData = [NSData dataWithContentsOfFile:fullPath];
    
    NSData *compressedData = [self compressData:uncompressedData];
    
    [compressedData writeToFile:zipPath atomically:YES];
    
    
}


+ (NSData *) compressData: (NSData *) uncompressedData
{
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
}

@end
