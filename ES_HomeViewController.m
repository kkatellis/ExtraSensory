//
//  ES_HomeViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/29/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_HomeViewController.h"
#import "ES_SensorManager.h"
#import "ES_AppDelegate.h"
#import "ES_DataBaseAccessor.h"
#import "ES_Scheduler.h"
#import "ES_User.h"

@interface ES_HomeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *sampleFrequencyLabel;

@property (weak, nonatomic) IBOutlet UISlider *sampleFrequencySlider;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *activitiesButton;

@property (weak, nonatomic) IBOutlet UILabel *indicatorLabel;

@property (strong, nonatomic) ES_Scheduler *scheduler;

@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;

@end

@implementation ES_HomeViewController

@synthesize settings = _settings;
@synthesize scheduler = _scheduler;
@synthesize activitiesButton = _activitiesButton;
- (ES_Scheduler *) scheduler
{
    if (!_scheduler)
    {
        _scheduler = [ES_Scheduler new];
        _scheduler.isReady = YES;
        NSLog(@"Scheduler Created!");
    }
    return _scheduler;
}

- (ES_SettingsModel *) settings
{
    if (!_settings)
    {
        _settings = [ES_DataBaseAccessor newSettingsModel];
    }
    return _settings;
}

- (void) viewDidAppear:(BOOL)animated
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [self.uuidLabel setText: appDelegate.user.uuid];
    
/*    [self.settings addObserver:self
                    forKeyPath:@"sampleFrequency"
                       options:NSKeyValueObservingOptionNew
                       context:NULL];*/
}

/*- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( [keyPath isEqualToString: @"sampleFrequency"] )
        [self.sampleFrequencyLabel setText: [NSString stringWithFormat: @"%@", [object valueForKey:@"sampleFrequency"]] ];
}*/

- (void) viewWillDisappear:(BOOL)animated
{
//    [self.settings removeObserver:self forKeyPath:@"sampleFrequency"];
}

- (ES_SensorManager *)sensorManager
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.sensorManager;
}

/*- (IBAction)sliderValueChanged:(UISlider *)sender
{
    self.sensorManager.sampleFrequency = self.sampleFrequencySlider.value;
    
    [self.settings setValue: [NSNumber numberWithFloat: sender.value ]
                 forKeyPath: @"sampleFrequency"];
    
}*/

#define RECORDING_TEXT @"We are now recording!"
#define NOT_RECORDING_TEXT @"We are not currently recording."

- (IBAction)startScheduler:(UISwitch *)sender
{
    if (sender.isOn)
    {
        [self.scheduler setIsOn: YES];
        [self.scheduler sampleSaveSendCycler: self ];
        [self.indicatorLabel setText: RECORDING_TEXT];
    }
    else
    {
        [self.scheduler setIsOn:NO];
        [self.indicatorLabel setText: NOT_RECORDING_TEXT];
    }
    
}



- (void)viewDidLoad
{
    /*self.sampleFrequencySlider.minimumValue = 1.0;
    self.sampleFrequencySlider.maximumValue = 100.0;
    self.sampleFrequencyLabel.text = [NSString stringWithFormat: @"%.0f", self.sensorManager.sampleFrequency ];*/
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ActivitiesButton"])
    {
        ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [segue.destinationViewController setPredictions: appDelegate.predictions];
        NSLog(@"AppD predictions: %@", appDelegate.predictions );
    }
}


@end
