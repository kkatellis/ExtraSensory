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
@property (strong, nonatomic) IBOutlet UIButton *SendFeedback;
@property (strong, nonatomic) IBOutlet UIButton *LyingDown;
@property (strong, nonatomic) IBOutlet UIButton *Sitting;
@property (strong, nonatomic) IBOutlet UIButton *Standing;
@property (strong, nonatomic) IBOutlet UIButton *Walking;
@property (strong, nonatomic) IBOutlet UIButton *Running;
@property (strong, nonatomic) IBOutlet UIButton *Bicycling;
@property (strong, nonatomic) IBOutlet UIButton *Driving;

@end

@implementation ES_FeedbackViewController

@synthesize fromCell = _fromCell;

- (IBAction)send:(UIBarButtonItem *)sender
{
    
}


- (IBAction)lying:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
   _LyingDown.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    _Sitting.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Standing.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Walking.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Running.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Bicycling.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Driving.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
}

- (IBAction)sitting:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
    _LyingDown.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Sitting.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    _Standing.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Walking.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Running.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Bicycling.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Driving.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
}

- (IBAction)standing:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
    _LyingDown.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Sitting.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Standing.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    _Walking.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Running.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Bicycling.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Driving.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
}

- (IBAction)walking:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
    _LyingDown.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Sitting.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Standing.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Walking.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    _Running.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Bicycling.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Driving.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
}

- (IBAction)running:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
    _LyingDown.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Sitting.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Standing.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Walking.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Running.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    _Bicycling.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Driving.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
}

- (IBAction)bicycling:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
    _LyingDown.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Sitting.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Standing.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Walking.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Running.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Bicycling.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    _Driving.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
}

- (IBAction)driving:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
    _LyingDown.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Sitting.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Standing.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Walking.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Running.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Bicycling.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Driving.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
//[self setTitle: self.fromCell.textLabel.text];
    
    CALayer *btnLayer = [_SendFeedback layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];
    [btnLayer setBorderWidth:1.0f];
    [btnLayer setBorderColor:[[UIColor redColor] CGColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
