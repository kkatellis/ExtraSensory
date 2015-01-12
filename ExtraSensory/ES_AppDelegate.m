//
//  ES_AppDelegate.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//
//

#import "ES_AppDelegate.h"
#import "ES_SensorManager.h"
#import "ES_Scheduler.h"
#import "ES_NetworkAccessor.h"
#import "ES_DataBaseAccessor.h"
#import "ES_User.h"
#import "ES_Settings.h"
#import "ES_ActivityEvent.h"
#import "ES_AlertViewWithUserInfo.h"
#import "ES_FeedbackViewController.h"
#import "RaisedTabBarController.h"

// Some constants:
#define APP_NAME_TITLE_STR @"ExtraSensory"
#define FOUND_VERIFIED @"foundVerified"
#define NOT_NOW_BUTTON_STR @"Cancel"
#define YES_STR @"Yes"
#define CORRECT_STR @"Correct"
#define NOT_EXACTLY_STR @"Not exactly"
#define ALERT_DISMISS_TIME 45

@interface ES_AppDelegate()

@property ES_AlertViewWithUserInfo *latestAlert;
@property BOOL userSelectedDataCollectionOn;
@property (nonatomic) ES_Activity *exampleWithPredeterminedLabels;
@property (nonatomic, strong) NSDate *predeterminedLabelsValidUntil;
@property (nonatomic, strong) NSTimer *predeterminedLabelsExpirationTimer;

@end

@implementation ES_AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize uuid = _uuid;

@synthesize sensorManager = _sensorManager;

@synthesize networkStack = _networkStack;

@synthesize networkAccessor = _networkAccessor;

@synthesize predictions = _predictions;

@synthesize user = _user;

@synthesize countLySiStWaRuBiDr = _countLySiStWaRuBiDr;




- (ES_User *)user
{
    if (!_user)
    {
        _user = [ES_DataBaseAccessor user];
    }
    return _user;
}


- (NSMutableArray *) predictions
{
    if (!_predictions)
    {
        _predictions = [NSMutableArray new];
    }
    return _predictions;
}

- (ES_NetworkAccessor *)networkAccessor
{
    if (!_networkAccessor)
    {
        _networkAccessor = [ES_NetworkAccessor new];
    }
    return _networkAccessor;
}

- (NSMutableArray *) getUnsentZipFiles
{
    NSString *storagePath = [ES_DataBaseAccessor zipDirectory];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:storagePath error:nil];
    NSPredicate *zipPredicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.zip'"];
    NSMutableArray *zipFiles = [NSMutableArray arrayWithArray:[directoryContent filteredArrayUsingPredicate:zipPredicate]];
    
    return zipFiles;
}

- (void) updateNetworkStackFromStorageFilesIfEmpty
{
    if (self.networkStack.count <= 0)
    {
        NSLog(@"[appDelegate] Updating network stack (currently count zero) - adding the stored zip files");
        NSMutableArray *zipFiles = [self getUnsentZipFiles];
        for (NSString *filename in zipFiles)
        {
            [self pushOnNetworkStack:[NSString stringWithFormat:@"/%@",filename]];
        }
    }
    
    // If added files, call for upload operation:
    if (self.networkStack.count > 0)
    {
        NSLog(@"[appDelegate] after adding stored unsent zip files to the network stack, calling for upload.");
        [self.networkAccessor upload];
    }
}

- (NSMutableArray *)networkStack
{
    if (_networkStack)
    {
        return _networkStack;
    }
    
    _networkStack = [NSMutableArray new];
    [self updateNetworkStackFromStorageFilesIfEmpty];
    return _networkStack;
}

- (void) postNetworkStackNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkStackSize" object:self];
}

- (void) pushOnNetworkStack: (NSString *)file
{
    [self.networkStack addObject: file];
    [self postNetworkStackNotification];
    
    // Did we reach the limit of stack capacity:
    if (self.networkStack.count > [self.user.settings.maxZipFilesStored intValue])
    {
        [self turnOffDataCollection];
        NSString *message = @"Max storage capacity reached. Stopping data collection.";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ExtraSensory" message:message delegate:self cancelButtonTitle:@"o.k." otherButtonTitles: nil];
        [alert show];
    }
    
    [self updateApplicationBadge];
}


- (NSString *) getFirstOnNetworkStack
{
    return [self.networkStack firstObject];
}

- (BOOL) removeFromNetworkStackFile:(NSString *)filename
{
    for (int ii = 0; ii < [self.networkStack count]; ii++)
    {
        if ([filename isEqualToString:[self.networkStack objectAtIndex:ii]])
        {
            [self.networkStack removeObjectAtIndex:ii];
            [self postNetworkStackNotification];
            NSLog(@"[appDelegate] Removed file %@ (item %d) from the network stack",filename,ii);
            
            // Did we just go bellow the storage limit?
            if ([self.networkStack count] == ([self.user.settings.maxZipFilesStored intValue]-1))
            {
                [self turnOnOrOffDataCollectionIfNeeded];
            }
            return YES;
        }
    }
    
    NSLog(@"[appDelegate] !!! File %@ was not found in the network stack, so can't remove it.",filename);
    return NO;
}

- (BOOL) deleteFromStorageZipFile:(NSString *)filename
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *fullPath = [[ES_DataBaseAccessor zipDirectory] stringByAppendingString:filename];
    NSError *error;
    
    if (![fileMgr removeItemAtPath:fullPath error:&error])
    {
        NSLog(@"[appDelegate] !!! Failed deleting file %@ with error: %@",filename,[error localizedDescription]);
        return NO;
    }
    else
    {
        NSLog(@"[appDelegate] Supposedly deleted file: %@",fullPath);
        return YES;
    }
}

- (BOOL) removeFromeNetworkStackAndDeleteFile:(NSString *)filename
{
    BOOL res1 = [self removeFromNetworkStackFile:filename];
    BOOL res2 = [self deleteFromStorageZipFile:filename];
    return res1 && res2;
}




// Getter




- (ES_SensorManager *)sensorManager
{
    if (!_sensorManager)
    {
        _sensorManager = [ES_SensorManager new];
    }
    return _sensorManager;
}

- (ES_Scheduler *)scheduler
{
    if (!_scheduler)
    {
        _scheduler = [ES_Scheduler new];
        NSLog(@"[appDelegate] Created new scheduler!");
    }
    return _scheduler;
}





- (void) applicationDidFinishLaunching:(UIApplication *)application
{
    NSLog(@"[appDelegate] Application finished launching.");
    
    self.userSelectedDataCollectionOn = YES;
    
    // Create a location manager instance to determine if location services are enabled. This manager instance will be
    // immediately released afterwards.
    self.locationManager = [CLLocationManager new];
    // If location authorization wasn't decided yet, ask for it:
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        NSLog(@"[appDelegate] Prompting user for location authorization.");
        [self.locationManager requestAlwaysAuthorization];
    }
    else if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"[appDelegate] Alerting user that location is disabled and asking to enable it.");
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"ExtraSensory" message:@"You currently have location services disabled. It would be helpful if you allow the app to collect location data (please change your phone's privacy settings, location section)." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
    }
    else
    {
        NSLog(@"[appDelegate] App is authorized to use location services. Authorization status=%d",[CLLocationManager authorizationStatus]);
    }
//    [self.locationManager startUpdatingLocation];

    UIImage *navBackgroundImage = [UIImage imageNamed:@"iOS7-blue"];
    [[UINavigationBar appearance] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];

    [self.scheduler sampleSaveSendCycler];
    
    // Initialize the network stack:
    NSMutableArray *ns = self.networkStack;
    NSLog(@"[appDelegate] Network stack has items: %@",ns);
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"[appDelegate] App did become active");
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"[appDelegate] App did enter background");
    [ES_DataBaseAccessor save];
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"[appDelegate] Application was launched (with options)");
    if (!launchOptions)
    {
        [self applicationDidFinishLaunching:application];
        return YES;
    }
    
    NSLog(@"[appDelegate] launched with options: %@",launchOptions);
    
    return YES;
}

- (void) applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"[appDelegate] Application is being terminated.");
    [ES_DataBaseAccessor save];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}





- (void) updateApplicationBadge
{
    NSInteger numUnlabeled = [ES_DataBaseAccessor howManyUnlabeledActivitiesToday];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:numUnlabeled];
}

- (void) userTurnedOffDataCollection
{
    self.userSelectedDataCollectionOn = NO;
    [self turnOffDataCollection];
}

- (BOOL) userTurnedOnDataCollection
{
    self.userSelectedDataCollectionOn = YES;
    return [self turnOnOrOffDataCollectionIfNeeded];
}

- (void) turnOffDataCollection
{
    [self.scheduler turnOffRecording];
}

- (BOOL) turnOnOrOffDataCollectionIfNeeded
{
    if ([self isDataCollectionSupposedToBeOn])
    {
        [self.scheduler sampleSaveSendCycler];
        return YES;
    }
    else
    {
        [self.scheduler turnOffRecording];
        return NO;
    }
}

- (BOOL) isDataCollectionSupposedToBeOn
{
    if (!self.userSelectedDataCollectionOn)
    {
        // Then shouldn't be on:
        NSLog(@"[appDelegate] DataCollection mechanism supposed to be 'off' (user selected so).");
        return NO;
    }
    
    int inStack = (int)[self.networkStack count];
    int limit = [self.user.settings.maxZipFilesStored intValue];
    NSLog(@"[appDelegate] Network stack has %lu items and storage limit is %@",(unsigned long)self.networkStack.count,self.user.settings.maxZipFilesStored);
    
    if (inStack < limit)
    {
        NSLog(@"[appDelegate] DataCollection mechanism should be on (user selected 'on' and network stack has less than limit).");
        return YES;
    }
    else
    {
        NSLog(@"[appDelegate] DataCollection mechanism should be off (user selected 'on' but network stack reached storage limit).");
        return NO;
    }
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.latestAlert)
    {
        [self dismissLatestAlert];
    }
    
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NOT_NOW_BUTTON_STR])
    {
        NSLog(@"[appDelegate] User pressed cancel button");
        return;
    }
    
    NSLog(@"[appDelegate] User pressed %@ button",[alertView buttonTitleAtIndex:buttonIndex]);
    
    if ([alertView isKindOfClass:[ES_AlertViewWithUserInfo class]])
    {
        ES_AlertViewWithUserInfo *alert = (ES_AlertViewWithUserInfo *)alertView;
        BOOL userApprovedLabels = ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:CORRECT_STR]);
        [self pushEitherActiveFeedbackOrActivityEventFeedbackAccordingToUserInfo:alert.userInfo userAlreadyApproved:userApprovedLabels];
    }
    
    // This is a good time to clear the app's notifications. We shouldn't keep old/irrelevant notifications in the center:
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void) pushEitherActiveFeedbackOrActivityEventFeedbackAccordingToUserInfo:(NSDictionary *)userInfo userAlreadyApproved:(BOOL)userApproved
{
    if (userInfo)
    {
        // Check if there was found a verified activity in the recent period of time:
        if ([userInfo valueForKey:FOUND_VERIFIED])
        {
            [self pushActivityEventFeedbackViewWithUserInfo:userInfo userAlreadyApproved:userApproved];
        }
        else
        {
            [self pushActiveFeedbackView];
        }
    }
    // Else, ignore!
}

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"[appDelegate] Caught local notification.");
    
    if (notification.userInfo)
    {
        // Check the application state we are in:
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
        {
            // Then the app is in background, and the user already got a notification (with the relevant question), and selected to click on it, so there is no need to alert the user again with the same question, and we can directly move to the updating view:
            [self pushEitherActiveFeedbackOrActivityEventFeedbackAccordingToUserInfo:notification.userInfo userAlreadyApproved:NO];
        }
        else
        {
            // Then the app is open on foreground, and we need to ask user if it's o.k. to switch to this nagged update right now.
            
            // Use the single alert we maintain. First see if there is an open one that we need to dismiss:
            [self dismissLatestAlert];
            if ([notification.userInfo valueForKey:FOUND_VERIFIED])
            {
                NSLog(@"[appDelegate] notification user info has verified labels. So preparing alert for activityEvent feedback");
                // Then prepare alert for activityEvent feedback:
                self.latestAlert = [[ES_AlertViewWithUserInfo alloc] initWithTitle:APP_NAME_TITLE_STR message:notification.alertBody delegate:self userInfo:notification.userInfo cancelButtonTitle:NOT_NOW_BUTTON_STR otherButtonTitles:CORRECT_STR,nil];
                [self.latestAlert addButtonWithTitle:NOT_EXACTLY_STR];
            }
            else
            {
                NSLog(@"[appDelegate] notification user info doesn't have verified labels. So preparing alert for active feedback");
                // Then prepare alert for clean-slate active feedback:
                self.latestAlert = [[ES_AlertViewWithUserInfo alloc] initWithTitle:APP_NAME_TITLE_STR message:notification.alertBody delegate:self userInfo:notification.userInfo cancelButtonTitle:NOT_NOW_BUTTON_STR otherButtonTitles:YES_STR,nil];
            }
                      
            [NSTimer scheduledTimerWithTimeInterval:ALERT_DISMISS_TIME target:self selector:@selector(dismissLatestAlert) userInfo:nil repeats:NO];
            [self.latestAlert show];
        }
    }
    
}

- (void) dismissLatestAlert
{
    if (self.latestAlert)
    {
        NSLog(@"[appDelegate] dismissing alert.");
        [self.latestAlert dismissWithClickedButtonIndex:self.latestAlert.cancelButtonIndex animated:NO];
        self.latestAlert = nil;
    }
}

- (NSMutableDictionary *) constructUserInfoForNaggingWithCheckTime:(NSNumber *)nagCheckTimestamp foundVerified:(BOOL)foundVerified main:(NSString *)mainActivity secondary:(NSArray *)secondaryActivitiesStrings moods:(NSArray *)moodsStrings latestVerifiedTime:(NSNumber *)latestVerifiedTimestamp
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:nagCheckTimestamp forKey:@"nagCheckTimestamp"];
    
    if (foundVerified)
    {
        [userInfo setValue:@1 forKey:FOUND_VERIFIED];
        [userInfo setValue:mainActivity forKey:@"mainActivity"];
        [userInfo setValue:secondaryActivitiesStrings forKey:@"secondaryActivitiesStrings"];
        [userInfo setValue:moodsStrings forKey:@"moodsStrings"];
        [userInfo setValue:latestVerifiedTimestamp forKey:@"latestVerifiedTimestamp"];
    }
    else
    {
        [userInfo setValue:nil forKey:FOUND_VERIFIED];
    }
    
    return userInfo;
}

- (void) pushActiveFeedbackView
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ActiveFeedback" bundle:nil];
    ES_FeedbackViewController *activeFeedback = (ES_FeedbackViewController *)[storyboard instantiateViewControllerWithIdentifier:@"Feedback"];
    activeFeedback.feedbackType = ES_FeedbackTypeActive;
    activeFeedback.calledFromNotification = YES;
    activeFeedback.labelSource = LabelSourceNotificationBlank;
    
    UITabBarController *tbc = (UITabBarController *)self.window.rootViewController;
    UINavigationController *nav = (UINavigationController *)tbc.selectedViewController;
    [nav pushViewController:activeFeedback animated:NO];
}


- (void) pushActivityEventFeedbackViewWithUserInfo:(NSDictionary *)userInfo userAlreadyApproved:(BOOL)userApproved
{
    // Create an ES_ActivityEvent object to initially describe what was presumably done in the recent period of time:
    NSNumber *startTimestamp = [userInfo valueForKey:@"latestVerifiedTimestamp"];
    NSNumber *endTimestamp = [userInfo valueForKey:@"nagCheckTimestamp"];
    
    NSMutableArray *minuteActivities = [NSMutableArray arrayWithArray:[ES_DataBaseAccessor getActivitiesFrom:startTimestamp to:endTimestamp]];
    
    NSSet *secondaryActivitiesStringsSet = [NSSet setWithArray:[userInfo valueForKey:@"secondaryActivitiesStrings"]];
    NSSet *moodsStringsSet = [NSSet setWithArray:[userInfo valueForKey:@"moodsStrings"]];
    
    ES_ActivityEvent *activityEvent = [[ES_ActivityEvent alloc] initWithServerPrediction:@"" userCorrection:[userInfo valueForKey:@"mainActivity"] secondaryActivitiesStrings:secondaryActivitiesStringsSet moodsStrings:moodsStringsSet startTimestamp:[userInfo valueForKey:@"latestVerifiedTimestamp"] endTimestamp:[userInfo valueForKey:@"nagCheckTimestamp"] minuteActivities:minuteActivities];
    
    // If user already approved labels, we can send the feedback right-away, without opening the feedback view:
    if (userApproved)
    {
        ES_FeedbackViewController *controller = [[ES_FeedbackViewController alloc] init];
        controller.labelSource = LabelSourceNotificationAnswerCorrect;
        [controller submitFeedbackForActivityEvent:activityEvent];
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ActiveFeedback" bundle:nil];
    UIViewController *newView = [storyboard instantiateViewControllerWithIdentifier:@"Feedback"];
    ES_FeedbackViewController *activityFeedback = (ES_FeedbackViewController *)newView;
    activityFeedback.feedbackType = ES_FeedbackTypeActivityEvent;
    activityFeedback.activityEvent = activityEvent;
    activityFeedback.calledFromNotification = YES;
    activityFeedback.labelSource = LabelSourceNotificationAnsewrNotExactly;
    
    UITabBarController *tbc = (UITabBarController *)self.window.rootViewController;
    UINavigationController *nav = (UINavigationController *)tbc.selectedViewController;
    [nav pushViewController:activityFeedback animated:YES];
}

- (void) logNetworkStackAndZipFiles
{
    NSString *storagePath = [ES_DataBaseAccessor zipDirectory];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:storagePath error:nil];
    NSPredicate *zipPredicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.zip'"];
    NSArray *storedZipFiles = [directoryContent filteredArrayUsingPredicate:zipPredicate];
    
    NSLog(@"[appDelegate] Storage dir has =%lu= zip files and network stack has =%lu= files.",(unsigned long)storedZipFiles.count,(unsigned long)self.networkStack.count);
}

- (NSUUID *)uuid
{
    
    if (!_uuid)
        _uuid = [NSUUID UUID];
    return _uuid;
    
}

- (void) markRecordingRightNow
{
    NSLog(@"[appDelegate] Marking that we're recording now.");
    self.recordingRightNow = YES;
    RaisedTabBarController *rtbc = (RaisedTabBarController *)self.window.rootViewController;
    
    if (rtbc)
    {
        [rtbc showRecordingImage];
    }
}

- (void) markNotRecordingRightNow
{
    NSLog(@"[appDelegate] Marking that we're not recording now.");
    self.recordingRightNow = NO;
    RaisedTabBarController *rtbc = (RaisedTabBarController *)self.window.rootViewController;
    
    if (rtbc)
    {
        [rtbc hideRecordingImage];
    }
}

- (void) disablePlusButton
{
    NSLog(@"[appDelegate] Disabling plus button.");
    RaisedTabBarController *rtbc = (RaisedTabBarController *)self.window.rootViewController;
    
    if (rtbc)
    {
        [rtbc disablePlusButton];
    }
}

- (void) enablePlusButton
{
    NSLog(@"[appDelegate] Enabling plus button.");
    RaisedTabBarController *rtbc = (RaisedTabBarController *)self.window.rootViewController;
    
    if (rtbc)
    {
        [rtbc enablePlusButton];
    }
}

- (void) clearPredeterminedLabels
{
    NSLog(@"[appDelegate] Removing predetermined labels.");
    self.predeterminedLabelsValidUntil = nil;
    self.exampleWithPredeterminedLabels = nil;
    [self.predeterminedLabelsExpirationTimer invalidate];
    self.predeterminedLabelsExpirationTimer = nil;
}

- (void) clearPredeterminedLabelsAndTurnOnNaggingMechanism
{
    [self clearPredeterminedLabels];
    [self.scheduler setTimerForNaggingCheckup];
}

- (void) setLabelsFromNowOnUntil:(NSDate *)validUntil toBeSameAsForActivity:(ES_Activity *)activity
{
    NSLog(@"[appDelegate] Setting labels to be valid until %@.",validUntil);
    
    self.predeterminedLabelsValidUntil = validUntil;
    self.exampleWithPredeterminedLabels = activity;
    [self.scheduler turnOffNaggingMechanism];
    
    // Now need to set a timer to stop this predetermined labels:
    if (self.predeterminedLabelsExpirationTimer && [self.predeterminedLabelsExpirationTimer isValid])
    {
        [self.predeterminedLabelsExpirationTimer invalidate];
    }
    NSTimeInterval interval = [validUntil timeIntervalSinceNow];
    self.predeterminedLabelsExpirationTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(clearPredeterminedLabelsAndTurnOnNaggingMechanism) userInfo:nil repeats:NO];
}

- (ES_Activity *) getExampleActivityForPredeterminedLabels
{
    if ((self.exampleWithPredeterminedLabels == nil) || (self.predeterminedLabelsValidUntil == nil))
    {
        [self clearPredeterminedLabels];
        return nil;
    }
    
    // If there are predetermined labels, make sure they are not (accidentally) expired:
    if ([self.predeterminedLabelsValidUntil compare:[NSDate date]] == NSOrderedAscending)
    {
        // Then the predetermined labels expired and should be cleared:
        [self clearPredeterminedLabelsAndTurnOnNaggingMechanism];
        return nil;
    }
    
    return self.exampleWithPredeterminedLabels;
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) // if it wasn't already initialized...
    {
        // alloc & init
        _managedObjectContext = [NSManagedObjectContext new];
    }
    // bind to persistent store
    if (!_managedObjectContext.persistentStoreCoordinator)
        _managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    return _managedObjectContext;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator)
    {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] init];
    }
    
	NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"ExtraSensory.sqlite"];
    NSLog(@"[appDelegate] storePath: %@",storePath);
	/*
	 Set up the store.
	 For the sake of illustration, provide a pre-populated default store.
	 */
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"ExtraSensory" ofType:@"sqlite"];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
	
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	
	NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }
    
    return _persistentStoreCoordinator;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (!_managedObjectModel)
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return _managedObjectModel;
}


#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


@end
