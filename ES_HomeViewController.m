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
#import "ES_PieChartView.h"
#import "ES_ActivityStatistic.h"
#import "ES_ActiveFeedbackViewController.h"

@interface ES_HomeViewController ()
@property (strong, nonatomic) IBOutlet UISwitch *schedulerSwitch;

@property (weak, nonatomic) IBOutlet UILabel *sampleFrequencyLabel;

@property (weak, nonatomic) IBOutlet UISlider *sampleFrequencySlider;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *activitiesButton;
- (IBAction)Compose:(UIBarButtonItem *)sender;

@property NSMutableArray *activityCountArray;

@property (weak, nonatomic) IBOutlet UILabel *indicatorLabel;

@property (weak, nonatomic) IBOutlet UILabel *lyingTime;

@property (weak, nonatomic) IBOutlet UILabel *sittingTime;

@property (weak, nonatomic) IBOutlet UILabel *standingTime;

@property (weak, nonatomic) IBOutlet UILabel *walkingTime;

@property (weak, nonatomic) IBOutlet UILabel *runningTime;

@property (weak, nonatomic) IBOutlet UILabel *bikingTime;

@property (weak, nonatomic) IBOutlet UILabel *drivingTime;

@property (weak, nonatomic) IBOutlet ES_PieChartView *pieChartView;

@end

@implementation ES_HomeViewController

@synthesize settings = _settings;
@synthesize activitiesButton = _activitiesButton;

#define RECORDING_TEXT @"ON"
#define NOT_RECORDING_TEXT @"OFF"

- (void) viewDidAppear:(BOOL)animated
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCounts)
                                                 name:@"Activities"
                                               object:nil];
    
    [ES_DataBaseAccessor save];
    
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.activityCountArray = appDelegate.countLySiStWaRuBiDr;
    
    [self updateCounts];
}

- (void) updateCounts
{
//    self.lyingTime.text    = [self timeString: 0];
//    self.sittingTime.text  = [self timeString: 1];
//    self.standingTime.text = [self timeString: 2];
//    self.walkingTime.text  = [self timeString: 3];
//    self.runningTime.text  = [self timeString: 4];
//    self.bikingTime.text   = [self timeString: 5];
//    self.drivingTime.text  = [self timeString: 6];
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.lyingTime.text    = [appDelegate.user.activityStatistics.countLying description];
    self.sittingTime.text  = [appDelegate.user.activityStatistics.countSitting description];
    self.standingTime.text = [appDelegate.user.activityStatistics.countStanding description];
    self.walkingTime.text  = [appDelegate.user.activityStatistics.countWalking description];
    self.runningTime.text  = [appDelegate.user.activityStatistics.countRunning description];
    self.bikingTime.text   = [appDelegate.user.activityStatistics.countBicycling description];
    self.drivingTime.text  = [appDelegate.user.activityStatistics.countDriving description];
    
    //self.pieChartView.activityCounts = self.activityCountArray;
    //[self.pieChartView setNeedsDisplay];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ES_DataBaseAccessor save];

}

- (ES_SensorManager *)sensorManager
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.sensorManager;
}

- (ES_Scheduler *)scheduler
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.scheduler;
}

- (IBAction)startScheduler:(UISwitch *)sender
{
    if (sender.isOn)
    {
        [self.indicatorLabel setText: RECORDING_TEXT];
        [self.scheduler setIsOn: YES];
        [self.scheduler sampleSaveSendCycler: self ];    }
    else
    {
        [self.indicatorLabel setText: NOT_RECORDING_TEXT];
        [self.scheduler setIsOn:NO];    }
    
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.schedulerSwitch.on)
    {
        [self.indicatorLabel setText: RECORDING_TEXT];
        [self.scheduler setIsOn: YES];
        [self.scheduler sampleSaveSendCycler: self ];
    }
    else
    {
        [self.indicatorLabel setText: NOT_RECORDING_TEXT];
        [self.scheduler setIsOn: NO];
    }
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


- (IBAction)Compose:(UIBarButtonItem *)sender {
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"ActiveFeedback" bundle:nil];
    ES_ActiveFeedbackViewController* initialView = [storyboard instantiateInitialViewController];
    initialView.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:initialView animated:YES completion:nil];
}
@end
