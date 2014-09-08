//
//  ES_HistoryTableViewController.m
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/10/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_HistoryTableViewController.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_ActivityStatistic.h"
#import "ES_DataBaseAccessor.h"
#import "ES_ActivityEvent.h"
#import "ES_ActivityEventTableCell.h"
#import "ES_ActivityEventFeedbackViewController.h"
#import "ES_UserActivityLabels.h"
#import "ES_ActivitiesStrings.h"

#define SECONDS_IN_24HRS 86400
#define TIMEGAP_TO_CONSIDER_SAME_EVENT 100

@interface ES_HistoryTableViewController ()

@property (nonatomic, retain) NSMutableArray * eventHistory;
@property (nonatomic) BOOL editingActivityEvent;
@property (nonatomic, retain) NSDate *timeInDayOfFocus;

@property (weak, nonatomic) IBOutlet UIButton *prevButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

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
        
        // colors:
//        NSArray *mainActivityLabels = [ES_ActivitiesStrings mainActivities];
//        NSArray *colors = [ES_ActivitiesStrings mainActivitiesColors];
//        self.colorForMainActivity = [NSDictionary dictionaryWithObjects:colors forKeys:mainActivityLabels];
//        NSLog(@"[historyTable] Initializing color dictionary: %@",self.colorForMainActivity);
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
    int lastRowIndex = (int)[self tableView:self.tableView numberOfRowsInSection:0] - 1;
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
    if (self.editingActivityEvent)
    {
        // Then we're just back from the activityEventFeedback view.
        self.editingActivityEvent = NO;
        [self refreshTable];
    }
    else
    {
        // Then we moved to this 'history' view from outside
        self.timeInDayOfFocus = [NSDate date];
        [self refreshTable];
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


- (IBAction)prevButtonTouchedDown:(id)sender {
    // Then go to previous day:
    self.timeInDayOfFocus = [self.timeInDayOfFocus dateByAddingTimeInterval:-SECONDS_IN_24HRS];
    [self refreshTable];
}

- (IBAction)nextButtonTouchedDown:(id)sender {
    // Then go to next day:
    self.timeInDayOfFocus = [self.timeInDayOfFocus dateByAddingTimeInterval:SECONDS_IN_24HRS];
    [self refreshTable];
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

+ (BOOL)shouldActivity:(ES_Activity *)newActivity beMergedToEventStartingWithActivity:(ES_Activity *)startActivity RightAfterActivity:(ES_Activity *)endActivity
{
    if (!endActivity)
    {
        return NO;
    }
    
    if (![self isActivity:newActivity similarToActivity:startActivity])
    {
        // Then they are not similar at all
        return NO;
    }
    
    if ([newActivity.timestamp doubleValue] < [endActivity.timestamp doubleValue])
    {
        // Then activity 2 is earlier than activity 1 and shouldn't be merged after it
        return NO;
    }
    
    if ([newActivity.timestamp doubleValue] > ([endActivity.timestamp doubleValue] + TIMEGAP_TO_CONSIDER_SAME_EVENT))
    {
        // Then activity 2 is too far apart after activity 1:
        return NO;
    }
    
    return YES;
}

+ (BOOL)isActivity:(ES_Activity *)activity1 similarToActivity:(ES_Activity *)activity2
{
    BOOL sameMainActivity = [self doesActivity:activity1 haveSameMainActivityAsActivity:activity2];
    
    BOOL sameSecondary = [self doesActivity:activity1 haveSameSecondaryActivitiesAsActivity:activity2];

    BOOL sameMood = [self doesActivity:activity1 haveSameMoodAsActivity:activity2];
    
    BOOL same = sameMainActivity && sameSecondary && sameMood;
    return same;
}

- (NSNumber *) getTimestampOfStartOfDay:(NSDate *)date
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
    NSDate *startOfDay = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    NSNumber *timestamp = [NSNumber numberWithDouble:[startOfDay timeIntervalSince1970]];
    
    return timestamp;
}

- (void)recalculateEventsFromPredictionList
{
    // Empty the event history:
    [self.eventHistory removeAllObjects];
    
    // Read the atomic activities from the DB:
    NSNumber *historyPageStart = [self getTimestampOfStartOfDay:self.timeInDayOfFocus];
    NSNumber *historyPageEnd = [NSNumber numberWithDouble:([historyPageStart doubleValue] + SECONDS_IN_24HRS)];
    
    NSArray *activities = [ES_DataBaseAccessor getWhileDeletingOrphansActivitiesFrom:historyPageStart to:historyPageEnd];
    
    // Group together consecutive timepoints with similar activities to unified activity-events:
    ES_Activity *startOfActivity = nil;
    ES_Activity *endOfActivity = nil;
    ES_ActivityEvent *currentEvent = nil;
    NSMutableArray *minuteActivities = nil;
    for (id activityObject in activities)
    {
        ES_Activity *currentActivity = (ES_Activity *)activityObject;

        
        if (![[self class] shouldActivity:currentActivity beMergedToEventStartingWithActivity:startOfActivity RightAfterActivity:endOfActivity])
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
        // Add the minute activity object to the list of minutes of the current event:
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
    return self.eventHistory.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = [self getDayStringForDate:[self timeInDayOfFocus]];
    return title;
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    UITableViewCell *header = [[UITableViewCell alloc] init];
//    header.textLabel.text = [self getDayStringForDate:[NSDate date]];
//    [header setBackgroundColor:[UIColor colorWithRed:0.1 green:0. blue:1. alpha:0.5]];
//    [self.tableView bringSubviewToFront:header];
//    
//    return header;
//}

- (NSString *) getDayStringForDate:(NSDate *)date
{
   
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"EEEE MMM-dd";
    NSString *dayStr = [formatter stringFromDate:date];
    
    // Is this day today?
    NSNumber *givenDateDayTimestamp = [self getTimestampOfStartOfDay:date];
    NSNumber *todaysTimestamp = [self getTimestampOfStartOfDay:[NSDate date]];
    if ([givenDateDayTimestamp isEqualToNumber:todaysTimestamp])
    {
        dayStr = [dayStr stringByAppendingString:@" (today)"];
    }
    
    return dayStr;
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
    
    NSString *startDateStr = [dateFormatter stringFromDate:startDate];
    NSString *endDateStr = [dateFormatter stringFromDate:endDate];
    
    NSString *dateString = nil;
    if ([endDateStr isEqualToString:startDateStr])
    {
        dateString = startDateStr;
    }
    else
    {
        dateString = [NSString stringWithFormat:@"%@ - %@",startDateStr,endDateStr];
    }

    cell.activityEvent = relevantEvent;
    
    NSString *mainActivityString;
    UIColor *color;
    if (relevantEvent.userCorrection)
    {
        mainActivityString = relevantEvent.userCorrection;
        color = [ES_ActivitiesStrings getColorForMainActivity:relevantEvent.userCorrection];
    }
    else
    {
        mainActivityString = [NSString stringWithFormat:@"%@?",relevantEvent.serverPrediction];
        color = [ES_ActivitiesStrings getColorForMainActivity:relevantEvent.serverPrediction];
    }
    
    NSString *mainText = [NSString stringWithFormat:@"%@   %@",dateString,mainActivityString];
    cell.textLabel.text = mainText;
    if (color)
    {
        [cell setBackgroundColor:color];
    }
    
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
