//
//  ES_FeedbackViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_FeedbackViewController.h"

@interface ES_FeedbackViewController ()
@property (weak, nonatomic) IBOutlet UILabel *correctActivityLabel;

@end

@implementation ES_FeedbackViewController

@synthesize fromCell = _fromCell;

- (IBAction)send:(UIBarButtonItem *)sender {
    
}


- (IBAction)lying:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
}

- (IBAction)sitting:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
}

- (IBAction)standing:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
}

- (IBAction)walking:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
}

- (IBAction)running:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
}

- (IBAction)bicycling:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
}

- (IBAction)driving:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
}



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
