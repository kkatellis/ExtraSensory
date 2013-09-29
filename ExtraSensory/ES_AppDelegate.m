//
//  ES_AppDelegate.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_AppDelegate.h"
#import "ES_SensorManager.h"

@implementation ES_AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize uuid = _uuid;

@synthesize sensorManager = _sensorManager;

@synthesize databaseQueue = _databaseQueue;

// Getter

- (dispatch_queue_t)databaseQueue
{
    if (!_databaseQueue)
    {
        return dispatch_queue_create( "ES_DataBaseQueue ", NULL );
    }
    return _databaseQueue;
    
}


- (ES_SensorManager *)sensorManager
{
    if (!_sensorManager)
    {
        _sensorManager = [ES_SensorManager new];
    }
    return _sensorManager;
}




/*- (NSUUID *)uuid
{
    if (!_uuid)
    {
        _uuid = [NSUUID UUID];

        NSManagedObjectContext *context = self.managedObjectContext;
        
        UserInfo *userInfo = [NSEntityDescription insertNewObjectForEntityForName:@"UserInfo" inManagedObjectContext:context];
        
        NSError *error = [[NSError alloc] init];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"UserInfo" inManagedObjectContext:context];
        
        [request setEntity:entity];
        
        NSArray *arr = [context executeFetchRequest:request error:&error];
        
        NSNumber *length = [NSNumber numberWithUnsignedInteger:[arr count]];
        
        if (length.integerValue == 0)
        {
            NSLog(@"There's no UUID in the database. Let's generate one!");
            userInfo.uuid = [_uuid UUIDString];
            
            NSError *error = [[NSError alloc] init];
            
            if (![context save:&error])
            {
                NSLog(@"Error saving UUID!");
            }
            return _uuid;
            
        }
        else if (length.integerValue == 1)
        {
            NSLog(@"There's one UUID in the database. Good!");
            return [arr objectAtIndex: 0];
        }
        else
        {
            NSLog(@"There's more than one UUID in the database...");
        }
    }
    return _uuid;
}*/

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
