//
//  ES_DataBaseAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Sample, ES_SettingsModel;

@interface ES_DataBaseAccessor : NSObject

+ (NSArray *) read: (NSString *)entityDescription;
+ (ES_Sample *) write;
+ (void) save;
+ (void) zipData;
+ (NSString *) applicationDocumentsDirectory;
+ (NSString *) dataDirectory;
+ (NSString *) zipDirectory;
+ (NSString *) serverResponseDirectory;
+ (ES_SettingsModel *) newSettingsModel;

@end
