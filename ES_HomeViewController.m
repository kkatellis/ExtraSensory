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
#import "ES_NetworkAccessor.h"
#import "ES_Scheduler.h"
#import "ES_User.h"
#import "ES_Settings.h"
#import "ES_ActivityStatistic.h"

@interface ES_HomeViewController ()

@property (strong, nonatomic) IBOutlet UILabel *mostRecentActivityLabel;
@property (strong, nonatomic) IBOutlet UIImageView *mostRecentActivityImage;
@property (weak, nonatomic) IBOutlet UILabel *networkStackSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *feedbackQueueSizeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *watchIcon;
- (IBAction)flushNetworkQueue:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;


@property NSMutableArray *activityCountArray;

@end

@implementation ES_HomeViewController

@synthesize settings = _settings;

#define RECORDING_TEXT @"ON"
#define NOT_RECORDING_TEXT @"OFF"


- (ES_AppDelegate *)appDelegate
{
    ES_AppDelegate *appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate;
}

- (void) viewDidAppear:(BOOL)animated
{
    [ES_DataBaseAccessor save];
}

-(void) viewWillAppear:(BOOL)animated
{
    [self updateMostRecentActivity];
    // Register to listen to activity-change notifications:
    [[NSNotificationCenter defaultCenter] addObserverForName:@"Activities" object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"[homeView] Caught activity change notification");
        NSNumber *timestamp = [[note userInfo] objectForKey:@"timestamp"];
        double secondsAgo = [[NSDate date] timeIntervalSince1970] - [timestamp doubleValue];
        if (!timestamp || (secondsAgo < 80)) {
            NSLog(@"[homeView] The updated activity is very recent, so update the view");
            [self updateMostRecentActivity];
        }
    }];
    
    // Current storage state:
    [self updateCurrentStorageLabel];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentStorageLabel) name:@"NetworkStackSize" object:[self appDelegate]];
    
    // Current feedback queue:
    [self updateCurrentFeedbackQueueLabel];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentFeedbackQueueLabel) name:@"FeedbackQueueSize" object:[self appDelegate]];
    
    // Watch:
    [self updateWatchIcon];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWatchIcon) name:@"WatchConnection" object:[[self appDelegate] watchProcessor]];
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ES_DataBaseAccessor save];
    
}

- (void) updateWatchIcon
{
    if ([[self appDelegate] isConnectedToWatch]) {
        NSLog(@"[homeView] Marking connected to watch");
        [self.watchIcon setImage:[UIImage imageNamed:@"watch_on.png"]];
    }
    else {
        NSLog(@"[homeView] Marking not connected to watch");
        [self.watchIcon setImage:[UIImage imageNamed:@"watch_off.png"]];
    }
}

- (void) updateMostRecentActivity
{
    // Are we in background? Cause if we are there is no use doing this computation:
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        NSLog(@"[homeView] Asked to update recent activity view, but we're not in foreground anyway, so there's no use.");
        return;
    }
    
    ES_Activity *activity = [ES_DataBaseAccessor getMostRecentActivity];
    
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
        
        if ([activityLabel isEqualToString:@"none"] || [activityLabel isEqualToString:@"don't remember"])
        {
            activityLabel = nil;
        }
        NSLog(@"[homeView] Drawing latest activity: %@ from time: %@",activityLabel,dateString);
    }
    // change the image & label
    if (activityLabel)
    {
        self.mostRecentActivityImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", activityLabel]];
        if (activity.userCorrection)
        {
            self.mostRecentActivityLabel.text = activityLabel;
        }
        else
        {
            // Then the activity label is a guess.
            self.mostRecentActivityLabel.text = [NSString stringWithFormat:@"%@?",activityLabel];
        }
    }
    else
    {
        self.mostRecentActivityImage.image = [UIImage imageNamed:@"house.png"];
        self.mostRecentActivityLabel.text = [NSString new];
    }
    
}


- (NSString *) timeString: (int) index
{
    ES_AppDelegate *appDelegate = [self appDelegate];
    self.activityCountArray = appDelegate.countLySiStWaRuBiDr;
    
    NSNumber *time = appDelegate.user.settings.timeBetweenSampling;
    NSNumber *numPredictions;
    NSLog(@"numPredictions = %@", numPredictions = [appDelegate.countLySiStWaRuBiDr objectAtIndex:index]);
    time = [NSNumber numberWithDouble: ([time doubleValue] * [numPredictions doubleValue])];
    
    time = [NSNumber numberWithDouble:([time doubleValue] / 60.0)];
    
    NSString *result = [NSString stringWithFormat:@"%@", time];
    return result;
}

- (ES_SensorManager *)sensorManager
{
    ES_AppDelegate *appDelegate = [self appDelegate];
    return appDelegate.sensorManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    ES_AppDelegate *appDelegate = [self appDelegate];
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
        ES_AppDelegate *appDelegate = [self appDelegate];
        [segue.destinationViewController setPredictions: appDelegate.predictions];
        NSLog(@"AppD predictions: %@", appDelegate.predictions );
    }
}

- (void) updateCurrentFeedbackQueueLabel
{
    NSString *fQString = @"";
    NSInteger qSize = [[self appDelegate] getFeedbackQueueSize];
    if (qSize > 0)
    {
        NSString *lastWord = (qSize == 1) ? @"label" : @"labels";
        fQString = [NSString stringWithFormat:@"Storing %lu %@",(long)qSize,lastWord];
    }
    self.feedbackQueueSizeLabel.text = fQString;
    [self updateButtonTitle];
}

- (void) updateCurrentStorageLabel
{
    NSString *storageString = @"";
    unsigned long storage = [self appDelegate].networkStack.count;
    if (storage > 0)
    {
        NSString *lastWord = (storage == 1) ? @"sample" : @"samples";
        storageString = [NSString stringWithFormat:@"Storing %lu %@",storage,lastWord];
    }
    self.networkStackSizeLabel.text = storageString;
    [self updateButtonTitle];
}

- (void) updateButtonTitle
{
    if ((self.appDelegate.networkStack.count > 0) | ([[self appDelegate] getFeedbackQueueSize] > 0)){
        [self.sendButton setTitle: @"Send" forState: UIControlStateNormal];
    } else {
        [self.sendButton setTitle: @"" forState: UIControlStateNormal];
    }
}

- (IBAction)flushNetworkQueue:(UIButton *)sender {
    [self.appDelegate.networkAccessor flush];
}
@end
