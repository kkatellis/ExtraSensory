//
//  ES_DataBaseAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Sample, ES_SettingsModel, ES_User, ES_Activity, ES_SensorSample;

@interface ES_DataBaseAccessor : NSObject

+ (NSArray *) read: (NSString *)entityDescription;
+ (void) save;
+ (NSString *) applicationDocumentsDirectory;
+ (NSString *) dataDirectory;
+ (NSString *) zipDirectory;
+ (void) writeData: (NSArray *)data;
+ (ES_User *) user;
+ (ES_Activity *) newActivity;
+ (ES_SensorSample *) newSensorSample;
+ (ES_Activity *) getActivityWithTime: (NSNumber *)time;
+ (void) writeActivity: (ES_Activity *)activity;


@end
