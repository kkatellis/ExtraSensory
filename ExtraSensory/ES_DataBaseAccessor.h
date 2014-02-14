//
//  ES_DataBaseAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Sample, ES_SettingsModel, ES_User, ES_Activity, ES_SensorSample, ES_UserActivityLabel;

@interface ES_DataBaseAccessor : NSObject

+ (NSArray *) read: (NSString *)entityDescription;
+ (void) save;
+ (NSString *) applicationDocumentsDirectory;
+ (NSString *) dataDirectory;
+ (NSString *) zipDirectory;
+ (void) writeData: (NSArray *)data;
+ (ES_User *) user;
+ (ES_Activity *) newActivity;
+ (void) deleteActivity: (ES_Activity *) activity;
+ (ES_SensorSample *) newSensorSample;
+ (void)addUserActivityLabel:(NSString *)label toActivity:(ES_Activity *)activity;
+ (void)removeUserActivityLabel:(NSString *)label fromActivity:(ES_Activity *)activity;
+ (ES_Activity *) getActivityWithTime: (NSNumber *)time;
+ (void) writeActivity: (ES_Activity *)activity;


@end
