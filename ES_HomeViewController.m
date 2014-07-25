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
#import "ES_CalendarViewController.h"

@interface ES_HomeViewController ()

@property (strong, nonatomic) IBOutlet UILabel *mostRecentActivityLabel;
@property (strong, nonatomic) IBOutlet UIImageView *mostRecentActivityImage;
- (IBAction)calendarButtonAction:(id)sender;

@property NSMutableArray *activityCountArray;

@property (weak, nonatomic) IBOutlet ES_PieChartView *pieChartView;

@end

@implementation ES_HomeViewController

@synthesize settings = _settings;

#define RECORDING_TEXT @"ON"
#define NOT_RECORDING_TEXT @"OFF"

- (void) viewDidAppear:(BOOL)animated
{
    [ES_DataBaseAccessor save];
}

-(void) viewWillAppear:(BOOL)animated
{
    //[self updateMostRecentActivity];
}

- (void) updateMostRecentActivity:(ES_Activity*) activity;
{
    //ES_Activity *mostRecentActivity = [ES_DataBaseAccessor getMostRecentActivity];
    //ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    //ES_Activity *mostRecentActivity = appDelegate.mostRecentActivity;
    NSString *activityLabel;
    NSString *dateString;
    if (activity)
    {
        // get time & label from activity object
        
        NSTimeInterval time = (NSTimeInterval)[activity.timestamp doubleValue];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"hh:mm a"];
        dateString = [NSString stringWithFormat: @"%@", [dateFormatter stringFromDate: [NSDate dateWithTimeIntervalSince1970: time]]];
        
        if (activity.userCorrection)
        {
            activityLabel = activity.userCorrection;
        } else
        {
            activityLabel = activity.serverPrediction;
        }
        
    }
    // change the image & label
    if (activityLabel)
    {
        self.mostRecentActivityImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", activityLabel]];
        //self.mostRecentActivityLabel.text = [NSString stringWithFormat:@"%@ at %@", activityLabel, dateString];
        self.mostRecentActivityLabel.text = activityLabel;
    }
    else
    {
        self.mostRecentActivityImage.image = [UIImage imageNamed:@"house.png"];
        self.mostRecentActivityLabel.text = [NSString new];
    }
    
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if ([keyPath isEqual:@"mostRecentActivity"]) {
        ES_Activity* changedActivity = [change objectForKey:NSKeyValueChangeNewKey];
        [self updateMostRecentActivity:changedActivity];
    }
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate addObserver:self
                  forKeyPath:@"mostRecentActivity"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
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


- (IBAction)ActiveFeedback:(UIButton *)sender {
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"ActiveFeedback" bundle:nil];
    ES_ActiveFeedbackViewController* initialView = [storyboard instantiateInitialViewController];
    initialView.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:initialView animated:YES completion:nil];
}
- (IBAction)calendarButtonAction:(id)sender {
    ES_CalendarViewController *calendarViewController = [[ES_CalendarViewController alloc] init];
    [self presentViewController:calendarViewController animated:YES completion:nil];

}
@end
