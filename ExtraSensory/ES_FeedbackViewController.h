//
//  ES_FeedbackViewController.h
//  ExtraSensory
//
//  Created by yonatan vaizman on 10/2/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ES_Activity.h"
#import "ES_ActivityEvent.h"
#import "ES_DataBaseAccessor.h"

typedef enum ES_FeedbackType : NSInteger
{
    ES_FeedbackTypeActive,
    ES_FeedbackTypeActivityEvent,
    ES_FeedbackTypeAtomicActivity
} ES_FeedbackType;

@interface ES_FeedbackViewController : UITableViewController

@property (nonatomic) ES_FeedbackType feedbackType;
@property (nonatomic) BOOL calledFromNotification;

@property (nonatomic) ES_LabelSource labelSource;

@property (nonatomic, strong) ES_Activity *preexistingActivity;
@property (nonatomic, strong) ES_ActivityEvent *activityEvent;

- (void) submitFeedbackForActivityEvent:(ES_ActivityEvent *)actEvent;

@end
