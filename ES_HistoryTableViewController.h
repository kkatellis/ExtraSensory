//
//  ES_HistoryTableViewController.h
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/10/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ES_Activity.h"
#import "ES_ActivityEvent.h"

@interface ES_HistoryTableViewController : UITableViewController

@property (nonatomic, strong) ES_ActivityEvent *eventToShowMinuteByMinute;

+ (BOOL)isActivity:(ES_Activity *)activity1 similarToActivity:(ES_Activity *)activity2; // to be used in other classes
+ (NSString *) getEventTitleUsingStartTimestamp:(NSNumber *)startTime endTimestamp:(NSNumber *)endTime;
+ (NSString *) getEventTitleUsingStartTimestamp:(NSNumber *)startTime;
@end
