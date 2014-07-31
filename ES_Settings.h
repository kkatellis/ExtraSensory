//
//  ES_Settings.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/6/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_User;

@interface ES_Settings : NSManagedObject

@property (nonatomic, retain) NSNumber * sampleDuration;
@property (nonatomic, retain) NSNumber * sampleRate;
@property (nonatomic, retain) NSNumber * timeBetweenSampling;
//@property (nonatomic, retain) NSNumber * timeBeforeNagUser;
@property (nonatomic, retain) ES_User *user;

@end
