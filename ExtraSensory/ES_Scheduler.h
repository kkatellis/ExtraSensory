//
//  ES_Scheduler.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/1/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ES_HomeViewController, ES_User, ES_Activity;

@interface ES_Scheduler : NSObject

@property BOOL isReady;

@property BOOL isOn;

@property (nonatomic, weak) ES_User* user;

- (void) sampleSaveSendCycler: (ES_HomeViewController *) homeViewController;
- (void) activeFeedback: (ES_Activity *) activity;
- (id) init;

@end
