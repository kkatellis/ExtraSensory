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
#import "ES_Settings.h"

@interface ES_HomeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *sampleFrequencyLabel;

@property (weak, nonatomic) IBOutlet UISlider *sampleFrequencySlider;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *activitiesButton;

@property NSMutableArray *activityCountArray;

@property (weak, nonatomic) IBOutlet UILabel *indicatorLabel;

@property (strong, nonatomic) ES_Scheduler *scheduler;

@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;

@property (weak, nonatomic) IBOutlet UILabel *lyingTime;

@property (weak, nonatomic) IBOutlet UILabel *sittingTime;

@property (weak, nonatomic) IBOutlet UILabel *standingTime;

@property (weak, nonatomic) IBOutlet UILabel *walkingTime;

@property (weak, nonatomic) IBOutlet UILabel *runningTime;

@property (weak, nonatomic) IBOutlet UILabel *bikingTime;

@property (weak, nonatomic) IBOutlet UILabel *drivingTime;


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

- (void) viewDidAppear:(BOOL)animated
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.activityCountArray = appDelegate.countLySiStWaRuBiDr;
    
    [self updateCounts];

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

- (void) updateCounts
{
    self.lyingTime.text    = [self timeString: 0];
    self.sittingTime.text  = [self timeString: 1];
    self.standingTime.text = [self timeString: 2];
    self.walkingTime.text  = [self timeString: 3];
    self.runningTime.text  = [self timeString: 4];
    self.bikingTime.text   = [self timeString: 5];
    self.drivingTime.text  = [self timeString: 6];
}

- (NSString *) timeString: (int) index
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.activityCountArray = appDelegate.countLySiStWaRuBiDr;
    
    NSNumber *time = appDelegate.user.settings.timeBetweenSampling;
    NSNumber *numPredictions;
    NSLog(@"numPredictions = %@", numPredictions = [appDelegate.countLySiStWaRuBiDr objectAtIndex:index]);
    time = [NSNumber numberWithDouble: ([time doubleValue] * [numPredictions doubleValue])];
    
    time = [NSNumber numberWithDouble:([time doubleValue] / 60.0)];
    
    NSString *result = [NSString stringWithFormat:@"%@", time];
    return result;
}

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

#define RECORDING_TEXT @"ON"
#define NOT_RECORDING_TEXT @"OFF"

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
