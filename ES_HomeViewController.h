//
//  ES_HomeViewController.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/29/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ES_SettingsModel;

@interface ES_HomeViewController : UIViewController

@property (nonatomic, strong) ES_SettingsModel *settings;

@property (weak, nonatomic) IBOutlet UITextView *logView;


@end
