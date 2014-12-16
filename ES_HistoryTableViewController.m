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
#import "ES_ActivityEventTableCell.h"
#import "ES_FeedbackViewController.h"
//#import "ES_UserActivityLabels.h"
#import "ES_SecondaryActivity.h"
#import "ES_Mood.h"
#import "ES_ActivitiesStrings.h"

#define SECONDS_IN_24HRS 86400
#define TIMEGAP_TO_CONSIDER_SAME_EVENT 100

@interface ES_HistoryTableViewController ()

@property (nonatomic, retain) NSMutableArray * eventHistory;
@property (nonatomic) BOOL editingActivityEvent;
@property (nonatomic, retain) NSDate *timeInDayOfFocus;

@property (weak, nonatomic) IBOutlet UIButton *prevButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (retain, nonatomic) NSNumber *markZoneStartTimestamp;
@property (retain, nonatomic) NSNumber *markZoneEndTimestamp;
//@property (retain, nonatomic) NSMutableSet *markZoneActivityEvents;

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
    int lastRowIndex = (int)[self tableView:self.tableView numberOfRowsInSection:0] - 1;
    if (lastRowIndex >= 0)
    {
        NSIndexPath *idp = [NSIndexPath indexPathForRow:lastRowIndex inSection:0];
        [self.tableView scrollToRowAtIndexPath:idp atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

- (void) clearMarkZone
{
    self.markZoneStartTimestamp = nil;
    self.markZoneEndTimestamp = nil;
}

- (void) refreshTableClearMarkZone:(BOOL)clearMarkZone
{
    if (self.eventToShowMinuteByMinute)
    {
        [self recalculateEventsFromGivenActivityEvent];
    }
    else
    {
        [self recalculateEventsFromDatabase];
    }
    
    if (clearMarkZone)
    {
        [self clearMarkZone];
    }
    [self.tableView reloadData];
    
    // The prev/next buttons:
    if (self.eventToShowMinuteByMinute)
    {
        // Then we're showing minutes of a single activityEvent. No need to allow moving to prev/next day. Instead need to add a "done" button:
        self.nextButton.enabled = NO;
        [self.nextButton setHidden:YES];
        [self.prevButton setTitle:@"Done" forState:UIControlStateNormal];
    }
    else
    {
        BOOL presentedDayIsToday = [self isTodaySameDayAsDate:self.timeInDayOfFocus];
        self.nextButton.enabled = !presentedDayIsToday;
        [self.nextButton setHidden:NO];
        [self.prevButton setTitle:@"previous day" forState:UIControlStateNormal];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    if (self.editingActivityEvent)
    {
        // Then we're just back from the activityEventFeedback view.
        self.editingActivityEvent = NO;
        [self refreshTableClearMarkZone:YES];
    }
    else
    {
        // Then we moved to this 'history' view from outside
        self.timeInDayOfFocus = [NSDate date];
        [self refreshTableClearMarkZone:YES];
        [self scrollToBottom];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableWithoutChangingMarkZone) name:@"Activities" object:nil];
}

- (void) refreshTableWithoutChangingMarkZone
{
    [self refreshTableClearMarkZone:NO];
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
    [self refreshTableClearMarkZone:YES];
    
    if (self.eventToShowMinuteByMinute)
    {
        // Then we are presenting a minute-by-minute breakdown, and the "prev" button is actually "done":
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)nextButtonTouchedDown:(id)sender {
    // Then go to next day:
    self.timeInDayOfFocus = [self.timeInDayOfFocus dateByAddingTimeInterval:SECONDS_IN_24HRS];
    [self refreshTableClearMarkZone:YES];
}

- (BOOL)allowEditingLabels
{
    NSNumber *startOfFocusDayTimestamp = [self getTimestampOfStartOfDay:self.timeInDayOfFocus];
    float diffSeconds = (float)[[NSDate date] timeIntervalSince1970] - [startOfFocusDayTimestamp floatValue];
    
    return (diffSeconds < 2*SECONDS_IN_24HRS);
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
    
    if (!activity1.serverPrediction && !activity2.serverPrediction)
    {
        return YES;
    }
    
    return [activity1.serverPrediction isEqualToString:activity2.serverPrediction];
}

/*
 * Compare 2 sets of ES_Label entities. Do they represent the same sets of labels (strings)
 */
+ (BOOL) isLabelSet:(NSSet *)labelObjects1 equalToLabelSet:(NSSet *)labelObjects2
{
    NSMutableSet *labelStrings1 = [NSMutableSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[labelObjects1 allObjects]]];
    NSMutableSet *labelStrings2 = [NSMutableSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[labelObjects2 allObjects]]];
    
    if ([labelStrings1 count] != [labelStrings2 count])
    {
        return NO;
    }
    
    NSMutableSet *diff = [NSMutableSet setWithSet:labelStrings1];
    [diff minusSet:labelStrings2];
    
    return ![diff count];
}

+ (BOOL)doesActivity:(ES_Activity *)activity1 haveSameSecondaryActivitiesAsActivity:(ES_Activity *)activity2
{
    return [self isLabelSet:activity1.secondaryActivities equalToLabelSet:activity2.secondaryActivities];
}

+ (BOOL)doesActivity:(ES_Activity *)activity1 haveSameMoodAsActivity:(ES_Activity *)activity2
{
    return [self isLabelSet:activity1.moods equalToLabelSet:activity2.moods];
//    if (activity1.mood)
//    {
//        return [activity1.mood isEqualToString:activity2.mood];
//    }
//    
//    return !(activity2.mood);
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
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    NSDate *startOfDay = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    NSNumber *timestamp = [NSNumber numberWithDouble:[startOfDay timeIntervalSince1970]];
    
    return timestamp;
}

- (void)recalculateEventsFromGivenActivityEvent
{
    // Empty the event history:
    [self.eventHistory removeAllObjects];
    
    // Add an activityEvent for each atomic activity:
    for (ES_Activity *atomicActivity in self.eventToShowMinuteByMinute.minuteActivities)
    {
        NSMutableSet *secondaryActivitiesStrings = [NSMutableSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[atomicActivity.secondaryActivities allObjects]]];
        NSMutableSet *moodsStrings = [NSMutableSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[atomicActivity.moods allObjects]]];
        
        ES_ActivityEvent *shortEvent = [[ES_ActivityEvent alloc] initWithServerPrediction:atomicActivity.serverPrediction userCorrection:atomicActivity.userCorrection secondaryActivitiesStrings:secondaryActivitiesStrings moodsStrings:moodsStrings startTimestamp:atomicActivity.timestamp endTimestamp:atomicActivity.timestamp minuteActivities:[NSMutableArray arrayWithObject:atomicActivity]];
        [self.eventHistory addObject:shortEvent];
    }
}

- (void)recalculateEventsFromDatabase
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
                NSMutableSet *secondaryActivitiesStrings = [NSMutableSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[startOfActivity.secondaryActivities allObjects]]];
                NSMutableSet *moodsStrings = [NSMutableSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[startOfActivity.moods allObjects]]];
                
                // Create an event from the start and end of the previous activity:
                currentEvent = [[ES_ActivityEvent alloc] initWithServerPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection secondaryActivitiesStrings:secondaryActivitiesStrings moodsStrings:moodsStrings startTimestamp:startOfActivity.timestamp endTimestamp:endOfActivity.timestamp minuteActivities:minuteActivities];
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
        NSMutableSet *secondaryActivitiesStrings = [NSMutableSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[startOfActivity.secondaryActivities allObjects]]];
        NSMutableSet *moodsStrings = [NSMutableSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[startOfActivity.moods allObjects]]];
        ES_ActivityEvent *event = [[ES_ActivityEvent alloc] initWithServerPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection secondaryActivitiesStrings:secondaryActivitiesStrings moodsStrings:moodsStrings startTimestamp:startOfActivity.timestamp endTimestamp:endOfActivity.timestamp minuteActivities:minuteActivities];
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
    NSString *title;
    if (self.eventToShowMinuteByMinute)
    {
        title = [ES_HistoryTableViewController getEventTitleUsingStartTimestamp:self.eventToShowMinuteByMinute.startTimestamp endTimestamp:self.eventToShowMinuteByMinute.endTimestamp];
    }
    else
    {
        title = [self getDayStringForDate:[self timeInDayOfFocus]];
    }
    return title;
}

+ (NSString *) getEventTitleUsingStartTimestamp:(NSNumber *)startTime endTimestamp:(NSNumber *)endTime
{
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[startTime floatValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[endTime floatValue]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    formatter.dateFormat = @"EEEE MMM-dd";
    NSString *dayStr = [formatter stringFromDate:startDate];
    
    formatter.dateFormat = @"HH:mm";
    NSString *startStr = [formatter stringFromDate:startDate];
    NSString *endStr = [formatter stringFromDate:endDate];
    
    NSString *title = [NSString stringWithFormat:@"%@ %@-%@",dayStr,startStr,endStr];
    
    return title;
}

- (BOOL) isTodaySameDayAsDate:(NSDate *)date
{
    NSNumber *givenDateDayTimestamp = [self getTimestampOfStartOfDay:date];
    NSNumber *todaysTimestamp = [self getTimestampOfStartOfDay:[NSDate date]];
    
    return ([givenDateDayTimestamp isEqualToNumber:todaysTimestamp]);
}

- (NSString *) getDayStringForDate:(NSDate *)date
{
   
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"EEEE MMM-dd";
    NSString *dayStr = [formatter stringFromDate:date];
    
    // Is this day today?
    if ([self isTodaySameDayAsDate:date])
    {
        dayStr = [dayStr stringByAppendingString:@" (today)"];
    }
    else if (![self allowEditingLabels])
    {
        dayStr = [dayStr stringByAppendingString:@" (view only)"];
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
    [dateFormatter setDateFormat:@"HH:mm"];
    
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
    else if (relevantEvent.serverPrediction)
    {
        mainActivityString = [NSString stringWithFormat:@"%@?",relevantEvent.serverPrediction];
        color = [ES_ActivitiesStrings getColorForMainActivity:relevantEvent.serverPrediction];
    }
    else
    {
        mainActivityString = @"??";
        color = nil;
    }
    
    NSString *mainText = [NSString stringWithFormat:@"%@   %@",dateString,mainActivityString];
    cell.textLabel.text = mainText;
    if (color)
    {
        [cell setBackgroundColor:color];
    }
    else
    {
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    
    NSString *eventDetails;
    if (relevantEvent.moodsStrings && [relevantEvent.moodsStrings count] > 0)
    {
        eventDetails = [[relevantEvent.moodsStrings allObjects] componentsJoinedByString:@", "];
    }
    else
    {
        eventDetails = @"";
    }
    
    if (relevantEvent.secondaryActivitiesStrings && [relevantEvent.secondaryActivitiesStrings count]>0)
    {
        NSString *secondaryStr = [NSString stringWithFormat:@"(%@)",[[relevantEvent.secondaryActivitiesStrings allObjects] componentsJoinedByString:@", "]];
        eventDetails = [NSString stringWithFormat:@"%@ %@",eventDetails,secondaryStr];
    }
    
    if ([eventDetails length] <= 0)
    {
        eventDetails = @" ";
    }
    cell.detailTextLabel.text = eventDetails;
    
    if ([self allowEditingLabels])
    {
        // Visually mark/unmark the cell according to the mark zone:
        [self changeVisualMarkingForCell:cell mark:[self checkIfCellShouldBeMarked:cell]];

        // Add a swipe gesture recognizer:
        UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGestureFromRecognizer:)];
        [recognizer setDirection:UISwipeGestureRecognizerDirectionRight];
        [cell addGestureRecognizer:recognizer];
    }
    
    return cell;
}

- (BOOL) checkIfCellShouldBeMarked:(ES_ActivityEventTableCell *)cell
{
    return [self checkIfActivityEventInMarkZone:cell.activityEvent];
}

- (BOOL) checkIfActivityEventInMarkZone:(ES_ActivityEvent *)activityEvent
{
    if (!self.markZoneStartTimestamp)
    {
        // Then no cell should be marked:
        return NO;
    }
    
    if (activityEvent.startTimestamp.doubleValue < self.markZoneStartTimestamp.doubleValue)
    {
        // Then this cell is earlier than the mark zone:
        return NO;
    }
    
    // Then check if current cell is not later than end of mark zone:
    return (activityEvent.startTimestamp.doubleValue <= self.markZoneEndTimestamp.doubleValue);
}

- (void) handleSwipeGestureFromRecognizer:(UISwipeGestureRecognizer *)recognizer
{
    ES_ActivityEventTableCell *cell = (ES_ActivityEventTableCell *)recognizer.view;
    NSNumber *cellTime = cell.activityEvent.startTimestamp;
    
    // If there is currently no mark zone:
    if (!self.markZoneStartTimestamp)
    {
        // Then mark this single cell as the mark zone:
        self.markZoneStartTimestamp = cellTime;
        self.markZoneEndTimestamp = cellTime;
    }
    else if (cellTime.doubleValue < self.markZoneStartTimestamp.doubleValue)
    {
        // If this cell is earlier than the current mark zone:
        self.markZoneStartTimestamp = cellTime;
    }
    else if (cellTime.doubleValue > self.markZoneEndTimestamp.doubleValue)
    {
        // If this cell is later than the current mark zone:
        self.markZoneEndTimestamp = cellTime;
    }
    else
    {
        // Then this cell is within the already marked zone.
        // Use this extra swipe as a signal to cancel the mark zone:
        self.markZoneStartTimestamp = nil;
        self.markZoneEndTimestamp = nil;
    }
    
    [self refreshTableWithoutChangingMarkZone];
    return;
}

- (void) changeVisualMarkingForCell:(ES_ActivityEventTableCell *)cell mark:(BOOL)mark
{
    if (mark)
    {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else
    {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
}

- (UIColor *) getChangedColor:(UIColor *)color clearer:(BOOL)clearer
{
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    CGFloat alpha;
    [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    alpha = (clearer) ? 0.2 : 1.0;
    
    UIColor *newColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    return newColor;
}

- (ES_ActivityEvent *) constructJointActivityEventFromMarkZone
{
    if (!self.markZoneStartTimestamp)
    {
        return nil;
    }
    
    ES_Activity *referenceForVerifiedLabels = nil;
    NSMutableArray *jointActivities = [NSMutableArray arrayWithCapacity:10];
    // Go over the events to collect the marked ones:
    for (ES_ActivityEvent *actEv in self.eventHistory)
    {
        // Is this event part of the mark zone:
        if (![self checkIfActivityEventInMarkZone:actEv])
        {
            continue;
        }
        
        // Does this even have user-verified labels:
        if (actEv.userCorrection)
        {
            // Check if we already have a verified reference:
            if (referenceForVerifiedLabels)
            {
                // Then we don't allow this mark zone to be merged:
                NSLog(@"[history] The mark zone has more than one labeled events. Can't merge it to a single event.");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ExtraSensory" message:@"The marked events contain more than one labeled event. Can't merge them to a single event." delegate:self cancelButtonTitle:@"O.K." otherButtonTitles: nil];
                [alert show];
                [self refreshTableClearMarkZone:YES];
                
                return nil;
            }
            
            referenceForVerifiedLabels = [actEv.minuteActivities firstObject];
        }
        
        // Add the atomic activities:
        [jointActivities addObjectsFromArray:actEv.minuteActivities];
    }
    
    if (jointActivities.count <= 0)
    {
        return nil;
    }
    
    // Construct the merged activity event:
    if (!referenceForVerifiedLabels)
    {
        referenceForVerifiedLabels = [jointActivities firstObject];
    }
    NSNumber *startTimestamp = self.markZoneStartTimestamp;
    NSNumber *endTimestamp = ((ES_Activity *)[jointActivities lastObject]).timestamp;
    NSSet *secondaryStrings = [NSSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[referenceForVerifiedLabels.secondaryActivities allObjects]]];
    NSSet *moodStrings = [NSSet setWithArray:[ES_ActivitiesStrings createStringArrayFromLabelObjectsAraay:[referenceForVerifiedLabels.moods allObjects]]];
    ES_ActivityEvent *mergedActivityEvent = [[ES_ActivityEvent alloc] initWithServerPrediction:referenceForVerifiedLabels.serverPrediction userCorrection:referenceForVerifiedLabels.userCorrection secondaryActivitiesStrings:secondaryStrings moodsStrings:moodStrings startTimestamp:startTimestamp endTimestamp:endTimestamp minuteActivities:jointActivities];
    
    return mergedActivityEvent;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath   *)indexPath
{
    if (![self allowEditingLabels])
    {
        return;
    }
    
    ES_ActivityEventTableCell *cell = (ES_ActivityEventTableCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    ES_ActivityEvent *activityEvent;
    if ([self checkIfCellShouldBeMarked:cell])
    {
        // If selected any cell in the mark zone, create a joint activity-event (if legal):
        activityEvent = [self constructJointActivityEventFromMarkZone];
        if (!activityEvent)
        {
            // The mark zone is illegal, so clear it:
            [self clearMarkZone];
            return;
        }
    }
    else
    {
        // If selected outside a mark zone, use the activity-event of the cell:
        activityEvent = cell.activityEvent;
    }
    
    [self segueToEditEvent:activityEvent];
}

- (void) segueToEditEvent:(ES_ActivityEvent *)activityEvent
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ActiveFeedback" bundle:nil];
    UIViewController *newView = [storyboard instantiateViewControllerWithIdentifier:@"Feedback"];
    ES_FeedbackViewController *feedback = (ES_FeedbackViewController *)newView;
    
    if (self.eventToShowMinuteByMinute)
    {
        // Then the feedback is for an atomic (single minute) activity:
        ES_Activity *atomicActivity = [activityEvent.minuteActivities firstObject]; // There should be only one object there
        
        feedback.preexistingActivity = atomicActivity;
        feedback.feedbackType = ES_FeedbackTypeAtomicActivity;
    }
    else
    {
        // Then the feedback is for a "long" activity event:
        feedback.activityEvent = activityEvent;
        feedback.feedbackType = ES_FeedbackTypeActivityEvent;
    }
    
    // Mark that we are moving to the feedback view:
    self.editingActivityEvent = YES;
    
    [self.navigationController pushViewController:feedback animated:YES];
}


#pragma mark - Navigation

 

@end
