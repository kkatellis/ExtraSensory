//
//  ES_FeedbackViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_FeedbackViewController.h"
#import "ES_CalendarViewCell.h"
#import "ES_Activity.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_ActivityStatistic.h"
#import "ES_NetworkAccessor.h"

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

@property (strong, nonatomic) NSString *databaseReferenceString;

@end

@implementation ES_FeedbackViewController

@synthesize fromCell = _fromCell;
@synthesize databaseReferenceString = _databaseReferenceString;


- (IBAction)correctedActivity:(UIButton *)sender {
    [self.correctActivityLabel setText: sender.titleLabel.text];
    
    _LyingDown.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Sitting.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Standing.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Walking.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Running.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Bicycling.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    _Driving.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    
    sender.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    
    if( [[sender.titleLabel.text description] isEqualToString: @"Lying Down"] )
        self.databaseReferenceString = @"Lying";
    else
        self.databaseReferenceString = [sender.titleLabel.text description];
    
    self.databaseReferenceString = [@"count" stringByAppendingString: self.databaseReferenceString];

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

- (IBAction)sendFeedback:(UIButton *)sender
{
    
    self.fromCell.activity.userCorrection = self.correctActivityLabel.text;
    
    
    ES_AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    
    int newCount = [[appDelegate.user.activityStatistics valueForKey: self.databaseReferenceString] intValue];
    
    newCount++;
    
    [appDelegate.user.activityStatistics setValue: [NSNumber numberWithInt: newCount] forKey: self.databaseReferenceString];
    NSLog(@"activity:%@",self.fromCell.activity);
    [appDelegate.networkAccessor sendFeedback:self.fromCell.activity];
    
    //int oldCount = appDelegate.user.activityStatistics valueForKey:
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"Activities" object: nil ];

    [self.navigationController popViewControllerAnimated:YES ];
}


@end
