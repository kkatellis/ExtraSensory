//
//  ES_MainActivityViewController.h
//  ExtraSensory
//
//  Created by Kat Ellis on 2/10/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ES_Activity.h"
#import "ES_ActiveFeedbackViewController.h"

@interface ES_MainActivityViewController : UITableViewController

@property NSMutableSet *appliedLabels; // the labels that the user has chosen
@property NSArray *choices; // the possible label choices

@end
