//
//  ES_FeedbackViewController.m
//  ExtraSensory
//
//  Created by yonatan vaizman on 10/2/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_FeedbackViewController.h"
#import "ES_SelectionFromListViewController.h"
#import "ES_Scheduler.h"
#import "ES_DataBaseAccessor.h"
#import "ES_AppDelegate.h"
#import "ES_NetworkAccessor.h"
#import "ES_ActivitiesStrings.h"
#import "ES_HistoryTableViewController.h"
#import "ES_UserActivityLabels.h"

#define MAIN_ACTIVITY @"Main Activity"
#define SECONDARY_ACTIVITIES @"Secondary Activities"
#define MOOD @"Mood"

#define VALID_FOR @"Valid for"

#define MAIN_ACTIVITY_CELL @"Main Activity cell"
#define SECONDARY_ACTIVITIES_CELL @"Secondary Activities cell"
#define MOOD_CELL @"Mood cell"
#define ACCESSORY_CELL @"Accessory cell"
#define SUBMIT_CELL @"Submit Feedback cell"

#define MAIN_ACTIVITY_SEC (int)0
#define SECONDARY_ACTIVITIES_SEC (int)1
#define MOOD_SEC (int)2
#define ACCESSORY_SEC (int)3
#define SUBMIT_SEC (int)4

#define WHITESPACE @" "
#define LESS_THAN_A_MINUTE @"less than a minute"

@interface ES_FeedbackViewController ()

@property (nonatomic, strong) NSString *mainActivity;
@property (nonatomic, strong) NSSet *secondaryActivities;
@property (nonatomic, strong) NSString *mood;

@property (nonatomic, strong) NSNumber *validForNumberOfMinutes;

@property (nonatomic) BOOL presentingMinuteByMinuteHistory;
@end

@implementation ES_FeedbackViewController

@synthesize preexistingActivity = _preexistingActivity;
@synthesize activityEvent = _activityEvent;

- (void) setPreexistingActivity:(ES_Activity *)activity
{
    _preexistingActivity = activity;
    // Update the labels for this feedback:
    if (activity.userCorrection)
    {
        self.mainActivity = activity.userCorrection;
    }
    else
    {
        self.mainActivity = activity.serverPrediction;
    }
    self.secondaryActivities = [NSMutableSet setWithArray:[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[activity.userActivityLabels allObjects]]];
    self.mood = activity.mood;
}

- (void) setActivityEvent:(ES_ActivityEvent *)activityEvent
{
    _activityEvent = activityEvent;
    // Update the labels for this feedback:
    if (activityEvent.userCorrection)
    {
        self.mainActivity = activityEvent.userCorrection;
    }
    else
    {
        self.mainActivity = activityEvent.serverPrediction;
    }
    self.secondaryActivities = activityEvent.userActivityLabels;
    self.mood = activityEvent.mood;
}

- (ES_AppDelegate *)appDelegate
{
    ES_AppDelegate *appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.presentingMinuteByMinuteHistory = NO;
}

- (void) viewWillAppear:(BOOL)animated
{
    if (self.presentingMinuteByMinuteHistory)
    {
        // Then we're back from the minute-by-minute history, and possibly edited some of the atomic activities, so the information we currently have here is no longer up to date. Need to pop back to History:
        [self.navigationController popViewControllerAnimated:NO];
        return;
    }
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancel:(id)sender {
    NSLog(@"[Feedback] Cancel button was pressed");
    [self leaveFeedbackView];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case MAIN_ACTIVITY_SEC:
            cell = [tableView dequeueReusableCellWithIdentifier:MAIN_ACTIVITY_CELL];
            if (self.mainActivity)
            {
                cell.detailTextLabel.text = self.mainActivity;
            }
            else
            {
                cell.detailTextLabel.text = WHITESPACE;
            }
            break;
        case SECONDARY_ACTIVITIES_SEC:
            cell = [tableView dequeueReusableCellWithIdentifier:SECONDARY_ACTIVITIES_CELL];
            if ((self.secondaryActivities) && ([self.secondaryActivities count] > 0))
            {
                NSMutableArray *stringArray = [NSMutableArray arrayWithArray:[self.secondaryActivities allObjects]];
                NSString *presentableString = [stringArray componentsJoinedByString:@", "];
                cell.detailTextLabel.text = presentableString;
            }
            else
            {
                cell.detailTextLabel.text = WHITESPACE;
            }
            break;
        case MOOD_SEC:
            cell = [tableView dequeueReusableCellWithIdentifier:MOOD_CELL];
            if (self.mood)
            {
                cell.detailTextLabel.text = self.mood;
            }
            else
            {
                cell.detailTextLabel.text = WHITESPACE;
            }
            break;
        case ACCESSORY_SEC:
            cell = [tableView dequeueReusableCellWithIdentifier:ACCESSORY_CELL];
            switch (self.feedbackType) {
                case ES_FeedbackTypeActive:
                    cell.textLabel.text = VALID_FOR;
                    cell.detailTextLabel.text = [self stringForValidForMinutes:self.validForNumberOfMinutes];
                    break;
                case ES_FeedbackTypeActivityEvent:
                    if ([self.activityEvent.minuteActivities count] <= 1) {
                        cell.detailTextLabel.text = @" ";
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    else
                    {
                        cell.detailTextLabel.text = @"Minute by minute labels";
                    }
                    cell.textLabel.text = [ES_HistoryTableViewController getEventTitleUsingStartTimestamp:self.activityEvent.startTimestamp endTimestamp:self.activityEvent.endTimestamp];
                    break;
                case ES_FeedbackTypeAtomicActivity:
                    [self setAsEmptyCell:cell];
                default:
                    break;
            }
            break;
        case SUBMIT_SEC:
            cell = [tableView dequeueReusableCellWithIdentifier:SUBMIT_CELL];
            break;
        default:
            break;
    }
    
    return cell;
}

- (NSString *) stringForValidForMinutes:(NSNumber *)numMinutes
{
    if (!numMinutes || [numMinutes intValue] <= 0)
    {
        return @" ";
    }
    
    return [NSString stringWithFormat:@"%@ minutes",numMinutes];
}

- (void) setAsEmptyCell:(UITableViewCell *)cell
{
    cell.textLabel.text = @" ";
    cell.detailTextLabel.text = @" ";
    cell.accessoryType = UITableViewCellAccessoryNone;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ACCESSORY_SEC)
    {
        switch (self.feedbackType) {
            case ES_FeedbackTypeActive:
                return indexPath;
                break;
            
            case ES_FeedbackTypeActivityEvent:
                if ([self.activityEvent.minuteActivities count] <= 1)
                {
                    // Then this activity event has only 1 minute. No need for minute-minute breakdown:
                    return nil;
                }
                return indexPath;
                break;
            
            case ES_FeedbackTypeAtomicActivity:
                return nil;
                break;
            
            default:
                return nil;
                break;
        }
    }
    else
    {
        return indexPath;
    }
    
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MAIN_ACTIVITY_SEC:
            // Let the storyboard seque handle it
            break;
        case SECONDARY_ACTIVITIES_SEC:
            // Let the storyboard seque handle it
            break;
        case MOOD_SEC:
            // Let the storyboard seque handle it
            break;
        case ACCESSORY_SEC:
            switch (self.feedbackType) {
                case ES_FeedbackTypeActive:
                    [self openSelectNumMinutesValidFor];
                    break;
                    
                case ES_FeedbackTypeActivityEvent:
                    [self openActivityEventMinuteHistory];
                    break;
                    
                case ES_FeedbackTypeAtomicActivity:
                    // Do nothing
                    break;
                    
                default:
                    break;
            }
            break;
        case SUBMIT_SEC:
            [self submitFeedback];
        default:
            break;
    }
}

- (NSArray *) choicesForMinutesValidFor
{
    NSArray *choices = @[LESS_THAN_A_MINUTE,@"2 minutes",@"5 minutes",@"10 minutes",@"15 minutes",@"20 minutes",@"25 minutes",@"30 minutes"];
    return choices;
}

- (void) openSelectNumMinutesValidFor
{
    NSArray *minuteChoices = [self choicesForMinutesValidFor];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ActiveFeedback" bundle:nil];
    ES_SelectionFromListViewController *selectionController = (ES_SelectionFromListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"SelectionFromList"];
    [selectionController setParametersCategory:VALID_FOR multiSelection:NO useIndex:NO choices:minuteChoices appliedLabels:nil frequentChoices:nil];
    [self.navigationController pushViewController:selectionController animated:YES];
}

- (void) openActivityEventMinuteHistory
{
    // First, mark that we're going to the minute-by-minute breakdown:
    self.presentingMinuteByMinuteHistory = YES;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ES_HistoryTableViewController *historyController = (ES_HistoryTableViewController *)[storyboard instantiateViewControllerWithIdentifier:@"History"];
    
    self.activityEvent.userCorrection = self.mainActivity;
    self.activityEvent.userActivityLabels = self.secondaryActivities;
    self.activityEvent.mood = self.mood;
    [self submitFeedbackForActivityEvent:self.activityEvent];
    
    historyController.eventToShowMinuteByMinute = self.activityEvent;
    
    [self.navigationController pushViewController:historyController animated:YES];
}

- (void) leaveFeedbackView
{
    if (self.calledFromNotification)
    {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    switch (self.feedbackType)
    {
        case ES_FeedbackTypeActive:
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            break;
            
        case ES_FeedbackTypeActivityEvent:
            [self.navigationController popViewControllerAnimated:YES];
            break;
            
        case ES_FeedbackTypeAtomicActivity:
            [self.navigationController popViewControllerAnimated:YES];
            break;
    }
    return;
}

- (void) submitFeedback
{

    ES_Activity *newActivity; // To be used only for active feedback
    
    switch (self.feedbackType) {
        case ES_FeedbackTypeActive:
            if (!self.mainActivity)
            {
                // Then we shouldn't do the active feedback.
                // TODO: Alert about the missing main activity:
                
                return;
            }
            // Create a new activity record:
            newActivity = [ES_DataBaseAccessor newActivity];
            // Fill the labels:
            newActivity.userCorrection = self.mainActivity;
            [ES_DataBaseAccessor setSecondaryActivities:[self.secondaryActivities allObjects] forActivity:newActivity];
            newActivity.mood = self.mood;
            
            // If the user used active feedback, there should be no more predetermined labels:
            if ([self.appDelegate getExampleActivityForPredeterminedLabels])
            {
                [self.appDelegate clearPredeterminedLabelsAndTurnOnNaggingMechanism];
            }
            
            // Active feedback:
            NSLog(@"[Feedback] Starting active feedback.");
            [[self appDelegate].scheduler activeFeedback:newActivity];
            [self leaveFeedbackView];
            break;
            
        case ES_FeedbackTypeActivityEvent:
            // Fill the labels:
            self.activityEvent.userCorrection = self.mainActivity;
            self.activityEvent.userActivityLabels = self.secondaryActivities;
            self.activityEvent.mood = self.mood;
            // Send the feedback:
            NSLog(@"[Feedback] Feedback from activity event.");
            [self submitFeedbackForActivityEvent:self.activityEvent];
            [self leaveFeedbackView];
            break;
            
        case ES_FeedbackTypeAtomicActivity:
            // Fill the labels:
            self.preexistingActivity.userCorrection = self.mainActivity;
            [ES_DataBaseAccessor setSecondaryActivities:[self.secondaryActivities allObjects] forActivity:self.preexistingActivity];
            self.preexistingActivity.mood = self.mood;
            // Send the feedback:
            NSLog(@"[Feedback] Feedback from atomic activity.");
            [self sendAtomicActivityLabelsIfRelevant:self.preexistingActivity];
            [self leaveFeedbackView];
            break;
            
        default:
            break;
    }
    
}

- (void) submitFeedbackForActivityEvent:(ES_ActivityEvent *)actEvent
{
    for (ES_Activity *act in actEvent.minuteActivities)
    {
        // Set the labels according to the activiey event:
        act.userCorrection = actEvent.userCorrection;
        [ES_DataBaseAccessor setSecondaryActivities:[actEvent.userActivityLabels allObjects] forActivity:act];
        act.mood = actEvent.mood;
        [self sendAtomicActivityLabelsIfRelevant:act];
    }
}

- (void) sendAtomicActivityLabelsIfRelevant:(ES_Activity *)act
{
    NSDate *time = [NSDate dateWithTimeIntervalSince1970:[act.timestamp floatValue]];
    
    // If relevant (if this timepoint's measurements already arrived at the server),
    // send the labels to the server:
    if (act.serverPrediction)
    {
        // Then the server has this timepoint's record and we already got the server's prediction. So send the user's labels feedback:
        NSLog(@"[Feedback] Sending feedback for time %@.",time);
        [[self appDelegate].networkAccessor sendFeedback:act];
    }
    else
    {
        NSLog(@"[Feedback] Activity of time %@ has no server prediction yet, so there's no point in sending label-feedback right now.",time);
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    ES_SelectionFromListViewController *selectionController = [segue destinationViewController];
    
    BOOL multiSelection;
    BOOL useIndex;
    NSArray *choices = nil;
    NSMutableSet *appliedLabels = nil;
    NSArray *frequentChoices = nil;
    
    if ([segue.identifier isEqualToString:MAIN_ACTIVITY])
    {
        multiSelection = NO;
        useIndex = NO;
        choices = [ES_ActivitiesStrings mainActivities];
        if (self.mainActivity)
        {
            appliedLabels = [NSMutableSet setWithObject:self.mainActivity];
        }
    }
    else if ([segue.identifier isEqualToString:SECONDARY_ACTIVITIES])
    {
        multiSelection = YES;
        useIndex = YES;
        choices = [ES_ActivitiesStrings secondaryActivities];
        if (self.secondaryActivities)
        {
            appliedLabels = [NSMutableSet setWithSet:self.secondaryActivities];
        }
        frequentChoices = [ES_DataBaseAccessor getTodaysFrequentSecondaryActivitiesOutOf:choices];
    }
    else if ([segue.identifier isEqualToString:MOOD])
    {
        multiSelection = NO;
        useIndex = YES;
        choices = [ES_ActivitiesStrings moods];
        if (self.mood)
        {
            appliedLabels = [NSMutableSet setWithObject:self.mood];
        }
        frequentChoices = [ES_DataBaseAccessor getTodaysFrequentMoodsOutOf:choices];
    }
    else
    {
        NSLog(@"[Feedback] !!! Unrecognized seque identifier: %@",segue.identifier);
        return;
    }
    
    [selectionController setParametersCategory:segue.identifier multiSelection:multiSelection useIndex:useIndex choices:choices appliedLabels:appliedLabels frequentChoices:frequentChoices];
}

-(IBAction)editedLabels:(UIStoryboardSegue *)segue
{
    if (![segue.sourceViewController isKindOfClass:[ES_SelectionFromListViewController class]])
    {
        NSLog(@"[Feedback] !!! unexpected unwind from segue");
        return;
    }
    
    ES_SelectionFromListViewController *selectionController = (ES_SelectionFromListViewController *)segue.sourceViewController;
    
    if ([selectionController.category isEqualToString:MAIN_ACTIVITY])
    {
        if (!selectionController.appliedLabels || [selectionController.appliedLabels count] <= 0)
        {
            NSLog(@"[Feedback] Back from selection list (for main activity) with nothing selected. So doing nothing.");
            return;
        }
        self.mainActivity = [[selectionController.appliedLabels allObjects] lastObject];
    }
    else if ([selectionController.category isEqualToString:SECONDARY_ACTIVITIES])
    {
        self.secondaryActivities = [NSSet setWithSet:selectionController.appliedLabels];
    }
    else if ([selectionController.category isEqualToString:MOOD])
    {
        if (!selectionController.appliedLabels || [selectionController.appliedLabels count] <= 0)
        {
            self.mood = nil;
        }
        else
        {
            self.mood = [[selectionController.appliedLabels allObjects] lastObject];
        }
    }
    else if ([selectionController.category isEqualToString:VALID_FOR])
    {
        if (!selectionController.appliedLabels || [selectionController.appliedLabels count] <= 0)
        {
            self.validForNumberOfMinutes = nil;
        }
        else
        {
            // There should be only a single selected value:
            NSString *selected = [[selectionController.appliedLabels allObjects] lastObject];
            if ([selected isEqualToString:LESS_THAN_A_MINUTE])
            {
                self.validForNumberOfMinutes = nil;
            }
            else
            {
                int numMinutes = [selected intValue];
                self.validForNumberOfMinutes = [NSNumber numberWithInt:numMinutes];
            }
        }
    }
        
}

@end
