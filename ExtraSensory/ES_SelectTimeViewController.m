//
//  ES_SelectTimeViewController.m
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/24/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_SelectTimeViewController.h"

@interface ES_SelectTimeViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (weak, nonatomic) IBOutlet UIButton *setButton;

- (void) setTheTimeAndGoBack;

@end

@implementation ES_SelectTimeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    NSString *buttonStr = [NSString stringWithFormat:@"set %@ time",self.timeName];
  
    [self.setButton setTitle:buttonStr forState:UIControlStateNormal];
    self.timePicker.date = self.selectedDate;
    self.timePicker.minimumDate = self.minDate;
    self.timePicker.maximumDate = self.maxDate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)setButtonTouchedDown:(id)sender {
    NSLog(@"==== tuch button");
    [self setTheTimeAndGoBack];
}

- (void) setTheTimeAndGoBack
{
    self.selectedDate = self.timePicker.date;
    [self.delegate receiveTime:self.timePicker.date for:self.isStartTime];
    NSLog(@"==== tuch button. after set selected data, before folding back");
    NSLog(@"==== after setting time ref: %lu and val: %@",(uintptr_t)self.selectedDate,self.selectedDate);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
