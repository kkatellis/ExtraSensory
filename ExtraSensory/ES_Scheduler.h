//
//  ES_Scheduler.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/1/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ES_HomeViewController;

@interface ES_Scheduler : NSObject

@property BOOL isReady;

@property BOOL isOn;

- (void) sampleSaveSendCycler: (ES_HomeViewController *) homeViewController;

@end
