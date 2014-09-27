//
//  ES_ActivityEventFeedbackViewController.m
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/14/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ActivityEventFeedbackViewController.h"
#import "ES_AppDelegate.h"
#import "ES_NetworkAccessor.h"
//#import "ES_MainActivityViewController.h"
#import "ES_SelectionFromListViewController.h"
#import "ES_ActivitiesStrings.h"
#import "ES_DataBaseAccessor.h"
#import "ES_UserActivityLabels.h"

#define MAIN_ACTIVITY_SEC (int)0
#define USER_ACTIVITIES_SEC (int)1
#define MOOD_SEC (int)2
#define TIMES_SEC (int)3
#define SEND_SEC (int)4

#define MAIN_ACTIVITY @"Main Activity"
#define SECONDARY_ACTIVITIES @"Secondary Activities"
#define MOOD @"Mood"
#define SUBMIT_FEEDBACK @"Submit feedback"
#define START_TIME @"Start time"
#define END_TIME @"End time"

@interface ES_ActivityEventFeedbackViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *mainActivityCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *otherActivitiesCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *moodCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *startTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *endTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *submitCell;



@end


@implementation ES_ActivityEventFeedbackViewController

- (void) receiveTime:(NSDate *)selectedTime for:(BOOL)startTime
{
    if (startTime)
    {
        self.startTime = selectedTime;
    }
    else
    {
        self.endTime = selectedTime;
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    // Get the current info of the relevant activity event:
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == TIMES_SEC)
    {
        return 2;
    }
    else
    {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == MAIN_ACTIVITY_SEC)
    {
        cell = self.mainActivityCell;
        cell.textLabel.text = MAIN_ACTIVITY;
        // Did the user already correcte the activity:
        if (!self.activityEvent.userCorrection)
        {
            // If not, initialize the user correction to the initial guess (the server prediction):
            self.activityEvent.userCorrection = self.activityEvent.serverPrediction;
        }
        
        self.mainActivityCell.detailTextLabel.text = self.activityEvent.userCorrection;
    }
    else if (indexPath.section == USER_ACTIVITIES_SEC)
    {
        cell = self.otherActivitiesCell;
        cell.textLabel.text = SECONDARY_ACTIVITIES;
        if (self.activityEvent.userActivityLabels)
        {
            NSMutableArray *stringArray = [NSMutableArray arrayWithArray:[self.activityEvent.userActivityLabels allObjects]];
            
            NSString *presentableUserActivities = [stringArray componentsJoinedByString:@", "];
            cell.detailTextLabel.text = presentableUserActivities;
        }
        else
        {
            cell.detailTextLabel.text = @"";
        }
    }
    else if (indexPath.section == MOOD_SEC)
    {
        cell = self.moodCell;
        cell.textLabel.text = MOOD;
        if (self.activityEvent.mood)
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",self.activityEvent.mood];
        }
        else
        {
            cell.detailTextLabel.text = @"";
        }
    }
    else if (indexPath.section == TIMES_SEC)
    {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"hh:mm"];
        NSString *startString = [dateFormatter stringFromDate:self.startTime];
        NSString *endString = [dateFormatter stringFromDate:self.endTime];
        
        if (indexPath.row == 0)
        {
            cell = self.startTimeCell;
            cell.detailTextLabel.text = startString;
        }
        else if (indexPath.row == 1)
        {
            cell = self.endTimeCell;
            cell.detailTextLabel.text = endString;
        }
    }
    else if (indexPath.section == SEND_SEC)
    {
        cell = self.submitCell;
        cell.textLabel.text = SUBMIT_FEEDBACK;
    }
    else
    {
        NSLog(@"!!! no match for section");
    }
    
    // Configure the cell...
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath   *)indexPath
{
    UIStoryboard *listSelectionStoryboard = [UIStoryboard storyboardWithName:@"ActiveFeedback" bundle:nil];
    ES_SelectionFromListViewController *activitySelection = (ES_SelectionFromListViewController *)[listSelectionStoryboard instantiateViewControllerWithIdentifier:@"SelectionFromList"];
    
    switch (indexPath.section) {
        case MAIN_ACTIVITY_SEC:
            if(self.activityEvent.userCorrection) // for samples which are not labeled by server
            {
                [activitySelection setAppliedLabels:[NSMutableSet setWithObject:(self.activityEvent.userCorrection)]];
            }
            [activitySelection setMultiSelection:NO];
            [activitySelection setChoices:[ES_ActivitiesStrings mainActivities]];
            [activitySelection setCategory:MAIN_ACTIVITY];
            [self.navigationController pushViewController:activitySelection animated:YES];
            break;
        case USER_ACTIVITIES_SEC:
            if (self.activityEvent.userActivityLabels)
            {
                [activitySelection setAppliedLabels: [NSMutableSet setWithSet:self.activityEvent.userActivityLabels]];
            }
            [activitySelection setMultiSelection:YES];
            [activitySelection setChoices:[ES_ActivitiesStrings secondaryActivities]];
            [activitySelection setCategory:SECONDARY_ACTIVITIES];
            [self.navigationController pushViewController:activitySelection animated:YES];
            break;
        case MOOD_SEC:
            if (self.activityEvent.mood)
            {
                [activitySelection setAppliedLabels:[NSMutableSet setWithObject:self.activityEvent.mood]];
            }
            else
            {
                [activitySelection setAppliedLabels:[NSMutableSet set]];
            }
            [activitySelection setMultiSelection:NO];
            [activitySelection setChoices:[ES_ActivitiesStrings moods]];
            [activitySelection setCategory:MOOD];
            [self.navigationController pushViewController:activitySelection animated:YES];
            break;
        case TIMES_SEC:
            switch (indexPath.row) {
                case 0:
                    [self setTimeFor:YES];
                    break;
                case 1:
                    [self setTimeFor:NO];
                    
                default:
                    break;
            }
            break;
        case SEND_SEC:
            [self submitFeedback];
            break;
            
        default:
            break;
    }
}

- (void) setTimeFor:(BOOL)settingStartTime
{
    
    // Prepare the time-selection view:
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ActivityEventFeedback" bundle:nil];
    UIViewController *newView = [storyboard instantiateViewControllerWithIdentifier:@"SetTime"];
    ES_SelectTimeViewController *selectTimeView = (ES_SelectTimeViewController *)newView;
    
    NSDate *tmp =[NSDate dateWithTimeIntervalSince1970:[self.activityEvent.startTimestamp doubleValue]];
    selectTimeView.minDate = tmp;
    selectTimeView.maxDate = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.endTimestamp doubleValue]];
    
    
    selectTimeView.selectedDate = settingStartTime ? self.startTime : self.endTime;
    selectTimeView.timeName = settingStartTime ? @"start" : @"end";
    
    selectTimeView.isStartTime = settingStartTime;
    selectTimeView.delegate = self;
    [self.navigationController pushViewController:selectTimeView animated:YES];
}

- (NSDate *) removeSecondsFromDate:(NSDate *)date
{
    int referenceTimeInterval = (int)[date timeIntervalSinceReferenceDate];
    int timeWithoutSeconds = 60 * (referenceTimeInterval / 60);
    NSDate *rounded = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeWithoutSeconds];
    
    return rounded;
}

- (void) submitFeedback
{
    
    ES_AppDelegate* appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSDate *eventStartTime = [self removeSecondsFromDate:self.startTime];
    NSDate *eventEndTime = [self removeSecondsFromDate:self.endTime];
    
    // Go over the minute activities of the original event:
    for (id minuteActivityObj in self.activityEvent.minuteActivities)
    {
        // Get the original object for this minute:
        ES_Activity *minuteActivity = (ES_Activity *)minuteActivityObj;
        
        NSDate * time = [NSDate dateWithTimeIntervalSince1970:[minuteActivity.timestamp doubleValue]];
        time = [self removeSecondsFromDate:time];
        
        // Is this minute now outside of the edited event's time period?
        if (([time compare:eventStartTime] == NSOrderedAscending) || ([time compare:eventEndTime] == NSOrderedDescending))
        {
            // Remove the userCorrection label, and leave the rest:
            [minuteActivity addUserActivityLabels:nil];
            //            minuteActivity.userCorrection = nil;
        }
        else
        {
            // Update this minute's activity according to the whole even's activity:
            
            // Main activity:
            minuteActivity.userCorrection = self.activityEvent.userCorrection;
            
            // Secondary activities:
            NSMutableArray *secondaryActivities = [NSMutableArray arrayWithArray:[self.activityEvent.userActivityLabels allObjects]];
            [ES_DataBaseAccessor setSecondaryActivities:secondaryActivities forActivity:minuteActivity];
            
            // Mood:
            if (self.activityEvent.mood)
            {
                [minuteActivity setMood:self.activityEvent.mood];
            }
            
        }
        // If relevant, send this minute's data to the server:
        if (minuteActivity.serverPrediction)
        {
            NSLog(@"[activityEventFeedback] Send feedback for time %@.",time);
            [appDelegate.networkAccessor sendFeedback:minuteActivity];
        }
        else
        {
            NSLog(@"[activityEventFeedback] Activity of time %@ has no server prediction yet, so no point in sending label-feedback right now.",time);
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)editedLabels:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[ES_SelectionFromListViewController class]])
    {
        ES_SelectionFromListViewController *selectionController = (ES_SelectionFromListViewController*)segue.sourceViewController;
        if ([selectionController.category isEqualToString:MAIN_ACTIVITY])
        {
            if ([selectionController.appliedLabels count] < 1)
            {
                // Then no main activity was selected. We should do nothing then:
                return;
            }
            self.activityEvent.userCorrection = [NSMutableArray arrayWithArray:[selectionController.appliedLabels allObjects]][[selectionController.appliedLabels count] -1];  // it must be the last element in the list (the count is always 1 for main activities)
        }
        else if ([selectionController.category isEqualToString:SECONDARY_ACTIVITIES])
        {
            if (selectionController.appliedLabels && (selectionController.appliedLabels.count > 0))
            {
                self.activityEvent.userActivityLabels = [NSSet setWithArray: [NSMutableArray arrayWithArray:[selectionController.appliedLabels allObjects]]];
            }
            else
            {
                self.activityEvent.userActivityLabels = nil;
            }
        }
        else if ([selectionController.category isEqualToString:MOOD])
        {
            if (selectionController.appliedLabels && (selectionController.appliedLabels.count > 0))
            {
                self.activityEvent.mood = [NSMutableArray arrayWithArray:[selectionController.appliedLabels allObjects]][0];
            }
            else
            {
                self.activityEvent.mood = nil;
            }
        }
        else
        {
            NSLog(@"!!! in edited labels. No match for category: %@",selectionController.category);
        }
    }
}


/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

@end