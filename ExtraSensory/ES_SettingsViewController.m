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
#import "ES_Scheduler.h"
#import "ES_Settings.h"

@interface ES_SettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (strong, nonatomic) IBOutlet UISwitch *schedulerSwitch;

@property (strong, nonatomic) IBOutlet UILabel *indicatorLabel;

@property (weak, nonatomic) IBOutlet UILabel *reminderIntervalSelectedValue;
@property (weak, nonatomic) IBOutlet UISlider *reminderIntervalSlider;

@property (weak, nonatomic) IBOutlet UILabel *numStoredSamplesLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeCoveredByStorageLabel;
@property (weak, nonatomic) IBOutlet UISlider *storageSlider;


@property (strong, nonatomic) ES_AppDelegate* appDelegate;
@end

#define RECORDING_TEXT @"ON"
#define NOT_RECORDING_TEXT @"OFF"

@implementation ES_SettingsViewController

- (ES_AppDelegate *) appDelegate
{
    if (!_appDelegate)
    {
        _appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

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
    
    // UUID:
    [self.uuidLabel setText: self.appDelegate.user.uuid];
    
    // Nag interval:
    NSNumber *reminderIntervalMins = [NSNumber numberWithInteger:((int)[self.appDelegate.user.settings.timeBetweenUserNags doubleValue])/60];
    [self setReminderIntervalSelectedValueWithMinutes:reminderIntervalMins];
    self.reminderIntervalSlider.value = [reminderIntervalMins doubleValue];
	// Do any additional setup after loading the view.
}

- (void)setReminderIntervalSelectedValueWithMinutes:(NSNumber *)minutes
{
    self.reminderIntervalSelectedValue.text = [NSString stringWithFormat:@"%@ minutes",minutes];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ES_Scheduler *)scheduler
{
    return self.appDelegate.scheduler;
}

- (IBAction)reminderSliderValueChanged:(id)sender {
    NSNumber *minutes = [NSNumber numberWithInteger:(int)self.reminderIntervalSlider.value];
    [self setReminderIntervalSelectedValueWithMinutes:minutes];
    NSNumber *seconds = [NSNumber numberWithDouble:(double)([minutes intValue]*60)];
    self.appDelegate.user.settings.timeBetweenUserNags = seconds;
}

- (IBAction)startScheduler:(UISwitch *)sender
{
    if (sender.isOn)
    {
        [self.indicatorLabel setText: RECORDING_TEXT];
        self.appDelegate.dataCollectionOn = YES;
        [[self scheduler] sampleSaveSendCycler];    }
    else
    {
        [self.indicatorLabel setText: NOT_RECORDING_TEXT];
        [[self scheduler] turnOffRecording];
    }
    
}

@end
