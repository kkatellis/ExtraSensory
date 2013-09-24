//
//  User.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SampleSet, Settings;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) SampleSet *sampleSet;
@property (nonatomic, retain) Settings *settings;

@end
