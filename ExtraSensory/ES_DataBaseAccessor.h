//
//  ES_DataBaseAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, ES_LabelSource)
{
    ES_LabelSourceDefault,
    ES_LabelSourceActiveFeedbackStart,
    ES_LabelSourceActiveFeedbackContinue,
    ES_LabelSourceHistory,
    ES_LabelSourceNotificationBlank,
    ES_LabelSourceNotificationAnswerCorrect,
    ES_LabelSourceNotificationAnsewrNotExactly
};

@class ES_Sample, ES_SettingsModel, ES_User, ES_Activity, ES_SensorSample, ES_UserActivityLabel, ES_Label, ES_SecondaryActivity, ES_Mood;

@interface ES_DataBaseAccessor : NSObject {
    
}

+ (NSString *)getMFCCFilename;
+ (NSString *)getHFDataFilename;
+ (NSString *)getAudioPropertiesFilename;
+ (NSString *) getDataFileFullPathForFilename:(NSString *)filename;

+ (NSArray *) read: (NSString *)entityDescription;
+ (void) save;
+ (NSString *) applicationDocumentsDirectory;
+ (NSString *) dataDirectory;
+ (NSString *) feedbackDirectory;
+ (NSString *) zipDirectory;
+ (void) writeData: (NSArray *)data;
+ (void) writeSensorData: (NSDictionary *)data;
+ (void) createFeedbackFile:(NSNumber *)timestamp;
+ (void) clearFeedbackFile:(NSNumber *)timestamp;
+ (void) clearDataFiles;
+ (ES_User *) user;
+ (ES_Activity *) newActivity;
+ (void) deleteActivity: (ES_Activity *) activity;
+ (BOOL) isActivityOrphanAndNowDeletedActivity:(ES_Activity *)activity;
+ (void) setSecondaryActivities:(NSArray*)labels forActivity: (ES_Activity *)activity;
+ (void) setMoods:(NSArray*)labels forActivity: (ES_Activity *)activity;
+ (ES_Activity *) getActivityWithTime: (NSNumber *)time;
+ (ES_Activity *) getMostRecentActivity;
+ (ES_Activity *) getLatestCorrectedActivityWithinTheLatest:(NSNumber *)seconds;
+ (NSMutableDictionary *) getTodaysCounts;
//+ (NSMutableDictionary *) getRecentCountsForSecondaryActivities:(NSArray *)secondaryActivities;
//+ (NSMutableDictionary *) getRecentCountsForMoods:(NSArray *)moods;

+ (NSArray *) getRecentFrequentSecondaryActivitiesOutOf:(NSArray *)secondaryActivities;
+ (NSArray *) getRecentFrequentMoodsOutOf:(NSArray *)moods;

+ (void) writeSensorData:(NSDictionary *)data andActivity:(ES_Activity *)activity;
+ (void) writeActivity: (ES_Activity *)activity;
+ (NSArray *) getActivitiesFrom:(NSNumber *)startTimestamp to:(NSNumber *)endTimestamp;
+ (int) howManyUnlabeledActivitiesToday;
+ (NSArray *) getWhileDeletingOrphansActivitiesFrom:(NSNumber *)startTimestamp to:(NSNumber *)endTimestamp;

@end
