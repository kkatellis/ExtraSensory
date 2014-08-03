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

@synthesize currentZipFilePath = _currentZipFilePath;

@synthesize countLySiStWaRuBiDr = _countLySiStWaRuBiDr;

@synthesize activitiesToUpload = _activitiesToUpload;

@synthesize mostRecentActivity = _mostRecentActivity;

- (NSMutableArray *)activitiesToUpload
{
    if (!_activitiesToUpload)
    {
        _activitiesToUpload = [NSMutableArray new];
    }
    return _activitiesToUpload;
}


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


- (void) pushOnNetworkStack: (NSString *)file
{
    if (!self.networkStack)
    {
        [self setNetworkStack: [NSMutableArray new]];
    }
    [self.networkStack addObject: file];
}

- (NSString *) popOffNetworkStack
{
    NSString *result = [self.networkStack lastObject];
    [self.networkStack removeLastObject];
    
    return result;
}

- (NSString *) getFirstOnNetworkStack
{
    return [self.networkStack firstObject];
}

- (void) removeFirstOnNetworkStack
{
    [self.networkStack removeObjectAtIndex: 0];
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

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (!launchOptions)
    {
        [self applicationDidFinishLaunching:application];
        return YES;
    }
    
    NSLog(@"=== launched with options: %@",launchOptions);
    return YES;
}

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"=== caught local notification: %@",notification);
    NSLog(@"=== app.badge: %ld",(long)application.applicationIconBadgeNumber);
    NSLog(@"=== notification badge: %ld",(long)notification.applicationIconBadgeNumber);
    if ([notification.userInfo valueForKey:@"foundVerified"])
    {
        [self pushActivityEventFeedbackViewWithUserInfo:notification.userInfo];
    }
}

- (NSMutableDictionary *) constructUserInfoForNaggingWithCheckTime:(NSNumber *)nagCheckTimestamp foundVerified:(BOOL)foundVerified main:(NSString *)mainActivity secondary:(NSArray *)secondaryActivitiesStrings mood:(NSString *)mood latestVerifiedTime:(NSNumber *)latestVerifiedTimestamp
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:nagCheckTimestamp forKey:@"nagCheckTimestamp"];
    
    if (foundVerified)
    {
        [userInfo setValue:@1 forKey:@"foundVerified"];
        [userInfo setValue:mainActivity forKey:@"mainActivity"];
        [userInfo setValue:secondaryActivitiesStrings forKey:@"secondaryActivitiesStrings"];
        [userInfo setValue:mood forKey:@"mood"];
        [userInfo setValue:latestVerifiedTimestamp forKey:@"latestVerifiedTimestamp"];
    }
    else
    {
        [userInfo setValue:nil forKey:@"foundVerified"];
    }
    
    return userInfo;
}

- (void) pushActivityEventFeedbackViewWithUserInfo:(NSDictionary *)userInfo
{
    // Create an ES_ActivityEvent object to initially describe what was presumably done in the recent period of time:
    NSNumber *startTimestamp = [userInfo valueForKey:@"latestVerifiedTimestamp"];
    NSNumber *endTimestamp = [userInfo valueForKey:@"nagCheckTimestamp"];
    
    NSMutableArray *minuteActivities = [NSMutableArray arrayWithArray:[ES_DataBaseAccessor getActivitiesFrom:startTimestamp to:endTimestamp]];
    
    ES_ActivityEvent *activityEvent = [[ES_ActivityEvent alloc] initWithIsVerified:nil serverPrediction:@"" userCorrection:[userInfo valueForKey:@"mainActivity"] userActivityLabels:[userInfo valueForKey:@"secondaryActivitiesStrings"] mood:[userInfo valueForKey:@"mood"] startTimestamp:[userInfo valueForKey:@"latestVerifiedTimestamp"] endTimestamp:[userInfo valueForKey:@"nagCheckTimestamp"] minuteActivities:minuteActivities];
    
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
