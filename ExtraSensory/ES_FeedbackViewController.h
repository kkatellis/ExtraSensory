//
//  ES_FeedbackViewController.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ES_CalendarViewCell;

@interface ES_FeedbackViewController : UIViewController

@property ES_CalendarViewCell *fromCell;

@property NSMutableArray *predictions;

@end
