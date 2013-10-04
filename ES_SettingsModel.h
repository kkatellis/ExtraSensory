//
//  ES_SettingsModel.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_User;

@interface ES_SettingsModel : NSManagedObject

@property (nonatomic, retain) NSNumber * sampleFrequency;
@property (nonatomic, retain) NSNumber * sampleDuration;
@property (nonatomic, retain) NSNumber * timeBetweenSamples;
@property (nonatomic, retain) ES_User *user;

@end
