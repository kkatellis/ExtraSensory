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
#import "ES_ActivityEventFeedbackViewController.h"
#import "ES_ActivityEvent.h"
#import "ES_AlertViewWithUserInfo.h"
#import "ES_ActiveFeedbackViewController.h"
#import "RaisedTabBarController.h"

// Some constants:
#define FOUND_VERIFIED @"foundVerified"
#define NOT_NOW_BUTTON_STR @"Not now!"
#define ALERT_DISMISS_TIME 45

@interface ES_AppDelegate()

@property ES_AlertViewWithUserInfo *latestAlert;

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

@synthesize mostRecentActivity = _mostRecentActivity;



// this should not exist. Use the ES_UserActivityStatistics
/*- (NSMutableArray *)countLySiStWaRuBiDr
{
    if (!_countLySiStWaRuBiDr)
    {
        _countLySiStWaRuBiDr = [[NSMutableArray alloc] initWithCapacity:7];
        for (int i = 0; i <7; i++)
        {
            [_countLySiStWaRuBiDr setObject: [NSNumber numberWithInt: 0] atIndexedSubscript: i];
        }
        NSLog( @"countArrayLength = %lu", (unsigned long)[_countLySiStWaRuBiDr count]);
    }
    return _countLySiStWaRuBiDr;
}*/


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

- (void) pushOnNetworkStack: (NSString *)file
{
    [self.networkStack addObject: file];
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
            NSLog(@"[appDelegate] Removed file %@ (item %d) from the network stack",filename,ii);
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
        NSLog(@"created new sheduler!");
    }
    return _scheduler;
}





- (void) applicationDidFinishLaunching:(UIApplication *)application
{
    NSLog( @"user = %@", self.user );
    NSLog( @"settings = %@", self.user.settings );
    
    // Create a location manager instance to determine if location services are enabled. This manager instance will be
    // immediately released afterwards.
    self.locationManager = [CLLocationManager new];
    /*if ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
     UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled. If you proceed, you will be asked to confirm whether location services should be reenabled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
     [servicesDisabledAlert show];
     }*/
    [self.locationManager startUpdatingLocation];
    UIImage *navBackgroundImage = [UIImage imageNamed:@"iOS7-blue"];
    [[UINavigationBar appearance] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];

    [self.scheduler sampleSaveSendCycler];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"=== app did become active");
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"=== app did enter background");
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"=== application was launched (with options)");
    if (!launchOptions)
    {
        [self applicationDidFinishLaunching:application];
        return YES;
    }
    
    NSLog(@"=== launched with options: %@",launchOptions);
    
//    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
//    if (notification)
//    {
//        if (notification.userInfo)
//        {
//            // Check if there was found a verified activity in the recent period of time:
//            if ([notification.userInfo valueForKey:FOUND_VERIFIED])
//            {
//                [self pushActivityEventFeedbackViewWithUserInfo:notification.userInfo];
//            }
//            else
//            {
//                [self pushActiveFeedbackView];
//            }
//        }
//    }
//    
    
    return YES;
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.latestAlert)
    {
        [self dismissLatestAlert];
    }
    
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NOT_NOW_BUTTON_STR])
    {
        NSLog(@"=== User pressed cancel button");
        return;
    }
    
    NSLog(@"=== User pressed %@ button",[alertView buttonTitleAtIndex:buttonIndex]);
    
    if ([alertView isKindOfClass:[ES_AlertViewWithUserInfo class]])
    {
        ES_AlertViewWithUserInfo *alert = (ES_AlertViewWithUserInfo *)alertView;
        [self pushEitherActiveFeedbackOrActivityEventFeedbackAccordingToUserInfo:alert.userInfo];
    }
    
    
}

- (void) pushEitherActiveFeedbackOrActivityEventFeedbackAccordingToUserInfo:(NSDictionary *)userInfo
{
    if (userInfo)
    {
        // Check if there was found a verified activity in the recent period of time:
        if ([userInfo valueForKey:FOUND_VERIFIED])
        {
            [self pushActivityEventFeedbackViewWithUserInfo:userInfo];
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
    NSLog(@"=== caught local notification: %@",notification);
    
    if (notification.userInfo)
    {
        // Check the application state we are in:
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
        {
            // Then the app is in background, and the user already got a notification (with the relevant question), and selected to click on it, so there is no need to alert the user again with the same question, and we can directly move to the updating view:
            [self pushEitherActiveFeedbackOrActivityEventFeedbackAccordingToUserInfo:notification.userInfo];
        }
        else
        {
            // Then the app is open on foreground, and we need to ask user if it's o.k. to switch to this nagged update right now.
            
            // Use the single alert we maintain. First see if there is an open one that we need to dismiss:
            [self dismissLatestAlert];
            self.latestAlert = [[ES_AlertViewWithUserInfo alloc] initWithTitle:@"ExtraSensory" message:notification.alertBody delegate:self userInfo:notification.userInfo cancelButtonTitle:NOT_NOW_BUTTON_STR otherButtonTitles:@"Update!",nil];
        
            [NSTimer scheduledTimerWithTimeInterval:ALERT_DISMISS_TIME target:self selector:@selector(dismissLatestAlert) userInfo:nil repeats:NO];
            [self.latestAlert show];
        }
    }
    
}

- (void) dismissLatestAlert
{
    if (self.latestAlert)
    {
        NSLog(@"=== dismissing alert.");
        [self.latestAlert dismissWithClickedButtonIndex:self.latestAlert.cancelButtonIndex animated:NO];
        self.latestAlert = nil;
    }
}

- (NSMutableDictionary *) constructUserInfoForNaggingWithCheckTime:(NSNumber *)nagCheckTimestamp foundVerified:(BOOL)foundVerified main:(NSString *)mainActivity secondary:(NSArray *)secondaryActivitiesStrings mood:(NSString *)mood latestVerifiedTime:(NSNumber *)latestVerifiedTimestamp
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:nagCheckTimestamp forKey:@"nagCheckTimestamp"];
    
    if (foundVerified)
    {
        [userInfo setValue:@1 forKey:FOUND_VERIFIED];
        [userInfo setValue:mainActivity forKey:@"mainActivity"];
        [userInfo setValue:secondaryActivitiesStrings forKey:@"secondaryActivitiesStrings"];
        [userInfo setValue:mood forKey:@"mood"];
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
    ES_ActiveFeedbackViewController* activeFeedbackInitial = [storyboard instantiateInitialViewController];
    activeFeedbackInitial.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UITabBarController *tbc = (UITabBarController *)self.window.rootViewController;
    UINavigationController *nav = (UINavigationController *)tbc.selectedViewController;
    [nav presentViewController:activeFeedbackInitial animated:YES completion:nil];
}


- (void) pushActivityEventFeedbackViewWithUserInfo:(NSDictionary *)userInfo
{
    // Create an ES_ActivityEvent object to initially describe what was presumably done in the recent period of time:
    NSNumber *startTimestamp = [userInfo valueForKey:@"latestVerifiedTimestamp"];
    NSNumber *endTimestamp = [userInfo valueForKey:@"nagCheckTimestamp"];
    
    NSMutableArray *minuteActivities = [NSMutableArray arrayWithArray:[ES_DataBaseAccessor getActivitiesFrom:startTimestamp to:endTimestamp]];
    
    NSSet *secondaryActivitiesStringsSet = [NSSet setWithArray:[userInfo valueForKey:@"secondaryActivitiesStrings"]];
    
    ES_ActivityEvent *activityEvent = [[ES_ActivityEvent alloc] initWithIsVerified:nil serverPrediction:@"" userCorrection:[userInfo valueForKey:@"mainActivity"] userActivityLabels:secondaryActivitiesStringsSet mood:[userInfo valueForKey:@"mood"] startTimestamp:[userInfo valueForKey:@"latestVerifiedTimestamp"] endTimestamp:[userInfo valueForKey:@"nagCheckTimestamp"] minuteActivities:minuteActivities];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ActivityEventFeedback" bundle:nil];
    UIViewController *newView = [storyboard instantiateViewControllerWithIdentifier:@"ActivityEventFeedbackView"];
    ES_ActivityEventFeedbackViewController *activityFeedback = (ES_ActivityEventFeedbackViewController *)newView;
    
    activityFeedback.activityEvent = activityEvent;
    activityFeedback.startTime = [NSDate dateWithTimeIntervalSince1970:[activityEvent.startTimestamp doubleValue]];
    activityFeedback.endTime = [NSDate dateWithTimeIntervalSince1970:[activityEvent.endTimestamp doubleValue]];

    UITabBarController *tbc = (UITabBarController *)self.window.rootViewController;
    UINavigationController *nav = (UINavigationController *)tbc.selectedViewController;
    [nav pushViewController:activityFeedback animated:YES];
}

- (NSUUID *)uuid
{
    
    if (!_uuid)
        _uuid = [NSUUID UUID];
    return _uuid;
    
}

- (void) markRecordingRightNow
{
    NSLog(@"=== Marking that we're recording now.");
    self.recordingRightNow = YES;
    RaisedTabBarController *rtbc = (RaisedTabBarController *)self.window.rootViewController;
    
    if (rtbc)
    {
        [rtbc showRecordingImage];
    }
}

- (void) markNotRecordingRightNow
{
    NSLog(@"=== Marking that we're not recording now.");
    self.recordingRightNow = NO;
    RaisedTabBarController *rtbc = (RaisedTabBarController *)self.window.rootViewController;
    
    if (rtbc)
    {
        [rtbc hideRecordingImage];
    }
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
