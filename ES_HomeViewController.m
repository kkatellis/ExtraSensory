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
#import "ES_SettingsModel.h"
#import "ES_DataBaseAccessor.h"
#import "ES_Scheduler.h"

@interface ES_HomeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *sampleFrequencyLabel;

@property (weak, nonatomic) IBOutlet UISlider *sampleFrequencySlider;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *activitiesButton;


@property (strong, nonatomic) ES_Scheduler *scheduler;

@end

@implementation ES_HomeViewController

@synthesize settings = _settings;
@synthesize scheduler = _scheduler;
@synthesize logView = _logView;
@synthesize activitiesButton = _activitiesButton;
- (ES_Scheduler *) scheduler
{
    if (!_scheduler)
    {
        _scheduler = [ES_Scheduler new];
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

- (IBAction)startScheduler:(UISwitch *)sender
{
    if (sender.isEnabled)
    {
        [self.scheduler sampleSaveSendCycler: self ];
    }
    else
    {
        NSLog( @"off!");
        exit(0);
    }
    
}



- (void)viewDidLoad
{
    self.sampleFrequencySlider.minimumValue = 1.0;
    self.sampleFrequencySlider.maximumValue = 100.0;
    self.sampleFrequencyLabel.text = [NSString stringWithFormat: @"%.0f", self.sensorManager.sampleFrequency ];
    
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
    NSLog( @"Prepare for segue %@", segue );
    if ([segue.identifier isEqualToString:@"ActivitiesButton"])
    {
        NSLog( @"segue identifier = Calendar View");
        ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [segue.destinationViewController setPredictions: appDelegate.predictions];
    }
}


@end
