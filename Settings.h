//
//  Settings.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AccelerometerSettings, User;

@interface Settings : NSManagedObject

@property (nonatomic, retain) User *user;
@property (nonatomic, retain) AccelerometerSettings *accelerometerSettings;

@end
