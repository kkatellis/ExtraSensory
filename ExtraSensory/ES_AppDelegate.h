//
//  ES_AppDelegate.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "ES_Activity.h"
#import "ES_WatchProcessor.h"

@class ES_SensorManager, ES_NetworkAccessor, ES_User, ES_Scheduler, RaisedTabBarController, ES_WatchProcessor;

@interface ES_AppDelegate : UIResponder <UIApplicationDelegate,UIAlertViewDelegate>

@property BOOL currentlyUploading;

@property BOOL recordingRightNow;

@property BOOL userSelectedDataCollectionOn;

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSUUID *uuid;

@property (strong, nonatomic) ES_SensorManager *sensorManager;

@property (strong, nonatomic) ES_WatchProcessor *watchProcessor;

@property (strong, nonatomic) ES_Scheduler *scheduler;

@property (strong, readonly, atomic) NSMutableArray *networkStack;

@property (strong, readonly, atomic) NSMutableArray *networkFeedbackQueueTimestamps;

@property (strong, nonatomic) ES_NetworkAccessor *networkAccessor;

@property (strong, nonatomic) NSMutableArray *predictions;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) ES_User *user;

@property (strong, nonatomic) NSMutableArray *countLySiStWaRuBiDr;



- (BOOL) userTurnedOnDataCollection;
- (void) userTurnedOffDataCollection;
- (void) turnOffDataCollection;
- (BOOL) isDataCollectionSupposedToBeOn;
- (BOOL) turnOnOrOffDataCollectionIfNeeded;

- (void) markRecordingRightNow;
- (void) markNotRecordingRightNow;
- (void) disablePlusButton;
- (void) enablePlusButton;
- (void) updateNetworkStackFromStorageFilesIfEmpty;
- (NSString *) getFirstOnNetworkStack;
- (BOOL) removeFromNetworkStackFile:(NSString *)filename;
- (BOOL) removeFromeNetworkStackAndDeleteFile:(NSString *)filename;
- (void) markStrikeForUploadingFile:(NSString *)filename;
- (void) pushOnNetworkStack: (NSString *) file;
- (void) logNetworkStackAndZipFiles;
- (void) updateApplicationBadge;
- (void) dismissLatestAlert;

- (NSInteger) getFeedbackQueueSize;
- (void) addToFeedbackQueueActivity:(ES_Activity *)activity;
- (void) removeFromFeedbackQueueTimestamp:(NSNumber *)timestamp;
- (ES_Activity *)getNextActivityInFeedbackQueue;

- (NSMutableDictionary *) constructUserInfoForNaggingWithCheckTime:(NSNumber *)nagCheckTimestamp foundVerified:(BOOL)foundVerified main:(NSString *)mainActivity secondary:(NSArray *)secondaryActivitiesStrings moods:(NSArray *)moodsStrings latestVerifiedTime:(NSNumber *)latestVerifiedTimestamp;

- (void) setLabelsFromNowOnUntil:(NSDate *)validUntil toBeSameAsForActivity:(ES_Activity *)activity;
- (ES_Activity *) getExampleActivityForPredeterminedLabels;
- (void) clearPredeterminedLabelsAndTurnOnNaggingMechanism;
- (void) pushActivityEventFeedbackViewWithUserInfo:(NSDictionary *)userInfo userAlreadyApproved:(BOOL)userApproved approvalFromWatch:(BOOL)fromWatch;

- (BOOL) isConnectedToWatch;

@end
