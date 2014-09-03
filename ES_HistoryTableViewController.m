//
//  ES_HistoryTableViewController.m
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/10/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_HistoryTableViewController.h"
//#import "ES_CalendarViewTableViewController.h"
#import "ES_AppDelegate.h"
//#import "ES_FeedbackViewController.h"
#import "ES_User.h"
#import "ES_ActivityStatistic.h"
#import "ES_DataBaseAccessor.h"
//#import "ES_CalendarViewCell.h"
#import "ES_ActivityEvent.h"
#import "ES_ActivityEventTableCell.h"
//#import "ES_EventEditAndFeedbackViewController.h"
#import "ES_ActivityEventFeedbackViewController.h"
#import "ES_UserActivityLabels.h"

#define SECONDS_IN_24HRS 86400

@interface ES_HistoryTableViewController ()

@property (nonatomic, retain) NSMutableArray * eventHistory;
@property (nonatomic) BOOL editingActivityEvent;

- (void) segueToEditEvent:(ES_ActivityEvent *)activityEvent;

@end

@implementation ES_HistoryTableViewController


- (NSMutableArray *)eventHistory
{
    if (!_eventHistory)
    {
        _eventHistory = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return _eventHistory;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.editingActivityEvent = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) scrollToBottom
{
    NSLog(@"[HistoryTableViewController] Scrolling to bottom");
    int lastRowIndex = [self tableView:self.tableView numberOfRowsInSection:0] - 1;
    NSIndexPath *idp = [NSIndexPath indexPathForRow:lastRowIndex inSection:0];
    [self.tableView scrollToRowAtIndexPath:idp atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void) refreshTable
{
    [self recalculateEventsFromPredictionList];
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self refreshTable];
    
    if (self.editingActivityEvent)
    {
        // Then we're just back from the activityEventFeedback view.
        self.editingActivityEvent = NO;
    }
    else
    {
        // Then we moved to this 'history' view from outside
        [self scrollToBottom];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"Activities" object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (BOOL)doesActivity:(ES_Activity *)activity1 haveSameMainActivityAsActivity:(ES_Activity *)activity2
{
    if (activity1.userCorrection)
    {
        return [activity1.userCorrection isEqualToString:activity2.userCorrection];
    }
    
    if (activity2.userCorrection)
    {
        return NO;
    }
    
    return [activity1.serverPrediction isEqualToString:activity2.serverPrediction];
}

+ (BOOL)doesActivity:(ES_Activity *)activity1 haveSameSecondaryActivitiesAsActivity:(ES_Activity *)activity2
{
    NSMutableSet *userActivitiesStrings1 = [NSMutableSet setWithArray:[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[activity1.userActivityLabels allObjects]]];
    
    NSMutableSet *userActivitiesStrings2 = [NSMutableSet setWithArray:[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[activity2.userActivityLabels allObjects]]];
    
    if ([userActivitiesStrings1 count] != [userActivitiesStrings2 count])
    {
        return NO;
    }
    
    NSMutableSet *diff = [NSMutableSet setWithSet:userActivitiesStrings1];
    [diff minusSet:userActivitiesStrings2];
    
    return ![diff count];
}

+ (BOOL)doesActivity:(ES_Activity *)activity1 haveSameMoodAsActivity:(ES_Activity *)activity2
{
    if (activity1.mood)
    {
        return [activity1.mood isEqualToString:activity2.mood];
    }
    
    return !(activity2.mood);
}

+ (BOOL)isActivity:(ES_Activity *)activity1 similarToActivity:(ES_Activity *)activity2
{
    BOOL sameMainActivity = [self doesActivity:activity1 haveSameMainActivityAsActivity:activity2];
    
    BOOL sameSecondary = [self doesActivity:activity1 haveSameSecondaryActivitiesAsActivity:activity2];

    BOOL sameMood = [self doesActivity:activity1 haveSameMoodAsActivity:activity2];
    
    BOOL same = sameMainActivity && sameSecondary && sameMood;
    return same;
}

- (void)recalculateEventsFromPredictionList
{
    // Empty the event history:
    [self.eventHistory removeAllObjects];
    
    // Read the atomic activities from the DB:
    NSNumber *now = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSNumber *historyStart = [NSNumber numberWithDouble:([now doubleValue] - SECONDS_IN_24HRS)];
    
    NSArray *activities = [ES_DataBaseAccessor getActivitiesFrom:historyStart to:now];

    // Group together consecutive timepoints with similar activities to unified activity-events:
    ES_Activity *startOfActivity = nil;
    ES_Activity *endOfActivity = nil;
    ES_ActivityEvent *currentEvent = nil;
    NSMutableArray *minuteActivities = nil;
    for (id activityObject in activities)
    {
        ES_Activity *currentActivity = (ES_Activity *)activityObject;

        
        if (![[self class] isActivity:currentActivity similarToActivity:startOfActivity])
        {
            // Then we've reached a new activity.
            if (startOfActivity)
            {
                NSMutableSet *userActivitiesStrings = [NSMutableSet setWithArray:[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[startOfActivity.userActivityLabels allObjects]]];
                // Create an event from the start and end of the previous activity:
                currentEvent = [[ES_ActivityEvent alloc] initWithIsVerified:startOfActivity.isPredictionVerified serverPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection userActivityLabels:userActivitiesStrings mood:startOfActivity.mood startTimestamp:startOfActivity.timestamp endTimestamp:endOfActivity.timestamp minuteActivities:minuteActivities];
                [self.eventHistory addObject:currentEvent];
            }
            
            //update the new "start" for the current activity:
            minuteActivities = [[NSMutableArray alloc] initWithCapacity:1];
            startOfActivity = currentActivity;
        }
        // Add teh minute activity object to the list of minutes of the current event:
        [minuteActivities addObject:currentActivity];
        endOfActivity = currentActivity;
    }
    if (endOfActivity)
    {
        // Create the last event from the start and end of activity:
        NSMutableSet *userActivitiesStrings = [NSMutableSet setWithArray:[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[startOfActivity.userActivityLabels allObjects]]];
        ES_ActivityEvent *event = [[ES_ActivityEvent alloc] initWithIsVerified:startOfActivity.isPredictionVerified serverPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection userActivityLabels:userActivitiesStrings mood:startOfActivity.mood startTimestamp:startOfActivity.timestamp endTimestamp:endOfActivity.timestamp minuteActivities:minuteActivities];
        [self.eventHistory addObject:event];
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.eventHistory.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ActivityEventCell";
    ES_ActivityEventTableCell *cell = (ES_ActivityEventTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    ES_ActivityEvent *relevantEvent = (ES_ActivityEvent *)[self.eventHistory objectAtIndex:indexPath.row];
    
    NSDate * startDate = [NSDate dateWithTimeIntervalSince1970:[relevantEvent.startTimestamp doubleValue]];
    NSDate * endDate = [NSDate dateWithTimeIntervalSince1970:[relevantEvent.endTimestamp doubleValue]];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    NSString *dateString = [NSString stringWithFormat:@"%@ - %@",[dateFormatter stringFromDate:startDate],[dateFormatter stringFromDate:endDate]];

    cell.activityEvent = relevantEvent;
    
    NSString *mainActivityString;
    if (relevantEvent.userCorrection)
    {
        mainActivityString = relevantEvent.userCorrection;
    }
    else
    {
        mainActivityString = [NSString stringWithFormat:@"%@?",relevantEvent.serverPrediction];
    }
    
    NSString *mainText = [NSString stringWithFormat:@"%@   %@",dateString,mainActivityString];
    cell.textLabel.text = mainText;
    
    NSString *eventDetails;
    if (relevantEvent.mood)
    {
        eventDetails = relevantEvent.mood;
    }
    else
    {
        eventDetails = @"";
    }
    
    if (relevantEvent.userActivityLabels && [relevantEvent.userActivityLabels count]>0)
    {
        NSString *secondaryStr = [NSString stringWithFormat:@"(%@)",[[relevantEvent.userActivityLabels allObjects] componentsJoinedByString:@", "]];
        eventDetails = [NSString stringWithFormat:@"%@ %@",eventDetails,secondaryStr];
    }
    
    cell.detailTextLabel.text = eventDetails;
    
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
    ES_ActivityEventTableCell *cell = (ES_ActivityEventTableCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    ES_ActivityEvent *activityEvent = cell.activityEvent;
    
    [self segueToEditEvent:activityEvent];
}

- (void) segueToEditEvent:(ES_ActivityEvent *)activityEvent
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ActivityEventFeedback" bundle:nil];
    UIViewController *newView = [storyboard instantiateViewControllerWithIdentifier:@"ActivityEventFeedbackView"];
    ES_ActivityEventFeedbackViewController *activityFeedback = (ES_ActivityEventFeedbackViewController *)newView;
    
    activityFeedback.activityEvent = activityEvent;
    activityFeedback.startTime = [NSDate dateWithTimeIntervalSince1970:[activityEvent.startTimestamp doubleValue]];
    activityFeedback.endTime = [NSDate dateWithTimeIntervalSince1970:[activityEvent.endTimestamp doubleValue]];
    
    // Mark that we are moving to the feedback view:
    self.editingActivityEvent = YES;
    
    [self.navigationController pushViewController:activityFeedback animated:YES];
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
//    ES_EventEditAndFeedbackViewController * editController = (ES_EventEditAndFeedbackViewController *)segue.destinationViewController;
//    editController.activityEvent = ((ES_ActivityEventTableCell *)sender).activityEvent;
}

 

@end
