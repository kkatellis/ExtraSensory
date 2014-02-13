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
#import "ES_Activity.h"
//#import "ES_CalendarViewCell.h"
#import "ES_ActivityEvent.h"

@interface ES_HistoryTableViewController ()

@property (nonatomic, retain) NSMutableArray * eventHistory;

+ (BOOL)isActivity:(ES_Activity *)activity1 similarToActivity:(ES_Activity *)activity2;

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

- (void) refreshTable
{
    [self recalculateEventsFromPredictionList];
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self refreshTable];
    
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

+ (BOOL)isActivity:(ES_Activity *)activity1 similarToActivity:(ES_Activity *)activity2
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

- (void)recalculateEventsFromPredictionList
{
    // Empty the event history:
    [self.eventHistory removeAllObjects];
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSMutableArray *predictions = appDelegate.predictions;
    // Read the prediction list of the user and group together consecutive timepoints with similar activities to unified activity events:
    ES_Activity *startOfActivity = nil;
    ES_Activity *endOfActivity = nil;
    for (id activityObject in [predictions reverseObjectEnumerator])
    {
        ES_Activity *currentActivity = (ES_Activity *)activityObject;
        
        if (![[self class] isActivity:currentActivity similarToActivity:startOfActivity])
        {
            // Then we've reached a new activity.
            if (startOfActivity)
            {
                // Create an event from the start and end of the previous activity:
                ES_ActivityEvent *event = [[ES_ActivityEvent alloc] initWithIsVerified:startOfActivity.isPredictionVerified serverPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection userActivityLabels:startOfActivity.userActivityLabels startTimestamp:startOfActivity.timestamp endTimestamp:endOfActivity.timestamp];
                [self.eventHistory addObject:event];
            }
            
            //update the new "start" for the current activity:
            startOfActivity = currentActivity;
        }
        endOfActivity = currentActivity;
    }
    if (endOfActivity)
    {
        // Create the last event from the start and end of activity:
        ES_ActivityEvent *event = [[ES_ActivityEvent alloc] initWithIsVerified:startOfActivity.isPredictionVerified serverPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection userActivityLabels:startOfActivity.userActivityLabels startTimestamp:startOfActivity.timestamp endTimestamp:endOfActivity.timestamp];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    ES_ActivityEvent *relevantEvent = (ES_ActivityEvent *)[self.eventHistory objectAtIndex:indexPath.row];
    
    NSDate * startDate = [NSDate dateWithTimeIntervalSince1970:[relevantEvent.startTimestamp doubleValue]];
    NSDate * endDate = [NSDate dateWithTimeIntervalSince1970:[relevantEvent.endTimestamp doubleValue]];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    NSString *dateString = [NSString stringWithFormat:@"%@ - %@",[dateFormatter stringFromDate:startDate],[dateFormatter stringFromDate:endDate]];

    cell.textLabel.text = dateString;
    
    if (relevantEvent.userCorrection)
    {
        cell.detailTextLabel.text = relevantEvent.userCorrection;
    }
    else
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@?",relevantEvent.serverPrediction];
    }
    
    
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
