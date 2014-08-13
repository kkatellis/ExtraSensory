//
//  ES_HistoryTableViewController.h
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/10/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ES_Activity.h"

@interface ES_HistoryTableViewController : UITableViewController
+ (BOOL)isActivity:(ES_Activity *)activity1 similarToActivity:(ES_Activity *)activity2; // to be used in other classes

@property (nonatomic, strong) NSMutableArray *predictions;

@end
