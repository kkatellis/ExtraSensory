//
//  ES_Mood.h
//  ExtraSensory
//
//  Created by yonatan vaizman on 11/25/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ES_Label.h"

@class ES_Activity;

@interface ES_Mood : ES_Label

@property (nonatomic, retain) ES_Activity *activity;

@end
