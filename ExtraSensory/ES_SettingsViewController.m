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
#import "ES_Settings.h"
#import "ES_DataBaseAccessor.h"

@interface ES_SettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (strong, nonatomic) IBOutlet UISwitch *schedulerSwitch;

@property (strong, nonatomic) IBOutlet UILabel *indicatorLabel;

@property (weak, nonatomic) IBOutlet UILabel *reminderIntervalSelectedValue;
@property (weak, nonatomic) IBOutlet UISlider *reminderIntervalSlider;

@property (weak, nonatomic) IBOutlet UILabel *numStoredSamplesLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeCoveredByStorageLabel;
@property (weak, nonatomic) IBOutlet UISlider *storageSlider;

@property (weak, nonatomic) IBOutlet UILabel *currentNetworkStackLabel;

@property (weak, nonatomic) IBOutlet UISwitch *homeSensingSwitch;
@property (weak, nonatomic) IBOutlet UILabel *homeSensingSwitchLabel;



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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // UUID:
    [self.uuidLabel setText: self.appDelegate.user.uuid];
    
    // Nag interval:
    NSNumber *reminderIntervalMins = [NSNumber numberWithInteger:((int)[self.appDelegate.user.settings.timeBetweenUserNags doubleValue])/60];
    [self setReminderIntervalSelectedValueWithMinutes:reminderIntervalMins];
    self.reminderIntervalSlider.value = [reminderIntervalMins doubleValue];

    // Storage capacity:
    NSNumber *numStoredSamples = self.appDelegate.user.settings.maxZipFilesStored;
    [self setStorageNumSamplesAndCoveredTimeLabelsWithSamples:numStoredSamples];
    self.storageSlider.value = [numStoredSamples doubleValue];
    
    // Network stack label:
    [self updateCurrentStorageLabel];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentStorageLabel) name:@"NetworkStackSize" object:self.appDelegate];
    
    // Home-sensing:
    self.homeSensingSwitch.on = [self.appDelegate.user.settings.homeSensingParticipant boolValue];
    [self updateHomeSensingSwitchLabel];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [ES_DataBaseAccessor save];
}

- (void) updateHomeSensingSwitchLabel
{
    if (self.homeSensingSwitch.on)
    {
        self.homeSensingSwitchLabel.text = @"ON";
    }
    else
    {
        self.homeSensingSwitchLabel.text = @"OFF";
    }
}

- (IBAction)homeSensingSwitchChanged:(id)sender {
    self.appDelegate.user.settings.homeSensingParticipant = [NSNumber numberWithBool:self.homeSensingSwitch.on];
    [self updateHomeSensingSwitchLabel];
}

- (void) updateCurrentStorageLabel
{
    NSString *networkString = [NSString stringWithFormat:@"Currently storing %lu samples.",(unsigned long)self.appDelegate.networkStack.count];
    self.currentNetworkStackLabel.text = networkString;
}

- (void) setStorageNumSamplesAndCoveredTimeLabelsWithSamples:(NSNumber *)samples
{
    int numSamples = (int)[samples intValue];
    self.numStoredSamplesLabel.text = [NSString stringWithFormat:@"%d",numSamples];
    
    // How much sample-time will that storage cover:
    // Assume approximately sample per minute.
    int hours = numSamples / 60;
    int minutes = numSamples - 60*hours;
    
    NSString *coverageTime;
    if (hours < 1)
    {
        coverageTime = [NSString stringWithFormat:@"(~%d mins)",minutes];
    }
    else
    {
        coverageTime = [NSString stringWithFormat:@"(~%d hrs %d mins)",hours,minutes];
    }
    self.timeCoveredByStorageLabel.text = coverageTime;
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

- (IBAction)storageSliderValueChanged:(id)sender {
    // Round the value to integer:
    NSNumber *numSamples = [NSNumber numberWithInt:(int)self.storageSlider.value];
    [self setStorageNumSamplesAndCoveredTimeLabelsWithSamples:numSamples];
    self.appDelegate.user.settings.maxZipFilesStored = [NSNumber numberWithDouble:[numSamples doubleValue]];
    
    // Don't yet check turn on/off data collection.
    // When the next push/remove comes to the network stack - then the check will be made.
}
- (IBAction)storageSliderTouchFinished:(id)sender {
    NSLog(@"[settings] Done dragging storage slider.");
    [self.appDelegate turnOnOrOffDataCollectionIfNeeded];
}

- (IBAction)startScheduler:(UISwitch *)sender
{
    if (sender.isOn)
    {
        [self.indicatorLabel setText: RECORDING_TEXT];
        BOOL isDataCollectionReallyStarting = [self.appDelegate userTurnedOnDataCollection];
        if (!isDataCollectionReallyStarting)
        {
            // Then user selected to activate the data collection mechanizm but probably there are too many zip files already in storage.
            NSString *message = @"Data collection is still inactive since the storage is in full capacity right now (until WiFi is available).";
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ExtraSensory" message:message delegate:self cancelButtonTitle:@"o.k." otherButtonTitles: nil];
            [alert show];
            
        }
    }
    else
    {
        [self.indicatorLabel setText: NOT_RECORDING_TEXT];
        [self.appDelegate userTurnedOffDataCollection];
    }
    
}

@end
