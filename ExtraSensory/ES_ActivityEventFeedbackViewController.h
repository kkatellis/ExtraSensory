//
//  ES_ActivityEventFeedbackViewController.h
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/14/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ES_ActivityEvent.h"

@interface ES_ActivityEventFeedbackViewController : UITableViewController

@property (nonatomic,strong) ES_ActivityEvent *activityEvent;
@property (nonatomic) NSDate *startTime;
@property (nonatomic) NSDate *endTime;

@end
