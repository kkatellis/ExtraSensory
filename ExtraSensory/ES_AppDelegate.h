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

@class ES_SensorManager, ES_NetworkAccessor, ES_User;

@interface ES_AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSUUID *uuid;

@property (strong, nonatomic) ES_SensorManager *sensorManager;

@property (strong, atomic) NSMutableArray *networkStack;

@property (strong, nonatomic) ES_NetworkAccessor *networkAccessor;

@property (strong, nonatomic) NSMutableArray *predictions;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) ES_User *user;

@property (strong, nonatomic) NSString *currentZipFilePath;

@property (strong, nonatomic) NSMutableArray *countLySiStWaRuBiDr;


- (void) pushOnNetworkStack: (NSString *) file;
- (NSString *) popOffNetworkStack;

@end
