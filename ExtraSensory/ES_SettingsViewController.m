//
//  ES_SettingsViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/11/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_SettingsViewController.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"

@interface ES_SettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@end

@implementation ES_SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [self.uuidLabel setText: appDelegate.user.uuid];

	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
