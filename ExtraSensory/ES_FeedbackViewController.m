//
//  ES_FeedbackViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_FeedbackViewController.h"

@interface ES_FeedbackViewController ()
@property (weak, nonatomic) IBOutlet UITableView *feedbackTableView;

@end

@implementation ES_FeedbackViewController

@synthesize fromCell = _fromCell;

@synthesize feedbackTableView = _feedbackTableView;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle: self.fromCell.textLabel.text];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
