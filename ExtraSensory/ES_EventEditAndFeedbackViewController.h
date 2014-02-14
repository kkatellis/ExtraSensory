//
//  ES_EventEditAndFeedbackViewController.h
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/13/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ES_ActivityEvent.h"

@interface ES_EventEditAndFeedbackViewController : UIViewController
    <UIPickerViewDelegate, UIPickerViewDataSource>

@property ES_ActivityEvent *activityEvent;


@end
