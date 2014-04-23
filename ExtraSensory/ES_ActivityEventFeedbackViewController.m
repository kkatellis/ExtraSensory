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
#import "ES_MainActivityViewController.h"
#import "ES_ActivitiesStrings.h"

#define MAIN_ACTIVITY_SEC (int)0
#define USER_ACTIVITIES_SEC (int)1
#define MOOD_SEC (int)2
#define TIMES_SEC (int)3
#define SEND_SEC (int)4

#define MAIN_ACTIVITY @"Main Activity"
#define SECONDARY_ACTIVITIES @"Secondary Activities"
#define MOOD @"Mood"

@interface ES_ActivityEventFeedbackViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *mainActivityCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *otherActivitiesCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *moodCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *startTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *endTimeCell;



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
    NSLog(@"==== in viewWillAppear");
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    NSString *startString = [dateFormatter stringFromDate:self.startTime];
    NSString *endString = [dateFormatter stringFromDate:self.endTime];
    
    self.startTimeCell.detailTextLabel.text = startString;
    self.endTimeCell.detailTextLabel.text =
        endString;
    
    // Did the user already correcte the activity:
    if (!self.activityEvent.userCorrection)
    {
        // If not, initialize the user correction to the initial guess (the server prediction):
        self.activityEvent.userCorrection = self.activityEvent.serverPrediction;
    }

    self.mainActivityCell.detailTextLabel.text = self.activityEvent.userCorrection;
    
    NSLog(@"=== before presenting useractivitys");
    NSLog(@"=== user activities are: %@", self.activityEvent.userActivityLabels);
    if (self.activityEvent.userActivityLabels)
    {
        NSLog(@"==== in view appear before displaying useractivities: %@",self.activityEvent.userActivityLabels);
        NSString *presentableUserActivities = [[self.activityEvent.userActivityLabels allObjects] componentsJoinedByString:@", "];
        NSLog(@"=== string looks like this: %@",presentableUserActivities);
        self.otherActivitiesCell.detailTextLabel.text = presentableUserActivities;
        NSLog(@"=== after setting text to present user activities");
    }
    else{
        NSLog(@"=== useractivity is null");
        self.otherActivitiesCell.detailTextLabel.text = @"belllla";
    }
    NSLog(@"=== after user activity presenting");
    
    if (self.activityEvent.mood)
    {
        self.moodCell.detailTextLabel.text = [NSString stringWithFormat:@"%@",self.activityEvent.mood];
    }
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

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//    
//    // Configure the cell...
//    
//    return cell;
//}
//
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
    UIViewController *newView = nil;
    ES_MainActivityViewController *activitySelection = nil;
    
    switch (indexPath.section) {
        case MAIN_ACTIVITY_SEC:
            newView = [listSelectionStoryboard instantiateViewControllerWithIdentifier:@"MainActivitySelection"];
            activitySelection = (ES_MainActivityViewController *)newView;

            [activitySelection setAppliedLabels:[NSMutableSet setWithObject:(self.activityEvent.userCorrection)]];
            [activitySelection setChoices:[ES_ActivitiesStrings mainActivities]];
            [activitySelection setCategory:MAIN_ACTIVITY];
            [self.navigationController pushViewController:activitySelection animated:YES];
            break;
        case USER_ACTIVITIES_SEC:
            newView = [listSelectionStoryboard instantiateViewControllerWithIdentifier:@"SecondaryActivitiesSelection"];
            activitySelection = (ES_MainActivityViewController *)newView;

            if (self.activityEvent.userActivityLabels)
            {
                [activitySelection setAppliedLabels: [NSMutableSet setWithSet: self.activityEvent.userActivityLabels]];
            }
            [activitySelection setChoices:[ES_ActivitiesStrings secondaryActivities]];
            [activitySelection setCategory:SECONDARY_ACTIVITIES];
            [self.navigationController pushViewController:activitySelection animated:YES];
            break;
        case MOOD_SEC:
            newView = [listSelectionStoryboard instantiateViewControllerWithIdentifier:@"MoodSelection"];
            activitySelection = (ES_MainActivityViewController *)newView;

            if (self.activityEvent.mood)
            {
                [activitySelection setAppliedLabels:[NSMutableSet setWithObject:self.activityEvent.mood]];
            }
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

- (void) submitFeedback
{

    NSLog(@"=== in submit feedback");
    ES_AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];

    // Go over the minute activities of the original event:
    for (id minuteActivityObj in self.activityEvent.minuteActivities)
    {
        // Get the original object for this minute:
        ES_Activity *minuteActivity = (ES_Activity *)minuteActivityObj;
        
        NSDate * time = [NSDate dateWithTimeIntervalSince1970:[minuteActivity.timestamp doubleValue]];
        NSLog(@"=== working on minute: %@" , time);
        // Is this minute now outside of the edited event's time period?
        if (([time compare:self.startTime] == NSOrderedAscending) || ([time compare:self.endTime] == NSOrderedDescending))
        {
            NSLog(@"=== this time is outside boutnds");
            // Remove the userCorrection label, and leave the rest:
            [minuteActivity addUserActivityLabels:nil];
//            minuteActivity.userCorrection = nil;
        }
        else
        {
            NSLog(@"=== this time should be updated with main: %@ and useractivities %@",self.activityEvent.userCorrection,self.activityEvent.userActivityLabels);
            // Copy the chosen labels from the edited activity event:
            minuteActivity.userCorrection = self.activityEvent.userCorrection;
            NSLog(@"==== after set user correction, before set useractitivies: %@",self.activityEvent.userActivityLabels);
            [minuteActivity addUserActivityLabels:self.activityEvent.userActivityLabels];
            
        }
        // Send this minute's data to the server:
        NSLog(@"=== send feedback for time %@",time);
        [appDelegate.networkAccessor sendFeedback:minuteActivity];
    }
    
    NSLog(@"=== popping back from feedback");
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)editedLabels:(UIStoryboardSegue *)segue
{
    NSLog(@"==== in editedLabels from segue: %@", segue);
    if ([segue.sourceViewController isKindOfClass:[ES_MainActivityViewController class]])
    {
        ES_MainActivityViewController *mavc = (ES_MainActivityViewController*)segue.sourceViewController;
        NSLog(@"==== segue unwinded back from selecting : %@" , mavc.category);
        NSLog(@"==== appliedlabels are: %@ and choises are: %@",mavc.appliedLabels,mavc.choices);
        if ([mavc.category isEqualToString:MAIN_ACTIVITY])
        {
            self.activityEvent.userCorrection = [NSMutableArray arrayWithArray:[mavc.appliedLabels allObjects]][0];
            NSLog(@"==== set the main activity to : %@", self.activityEvent.userCorrection);
        }
        else if ([mavc.category isEqualToString:SECONDARY_ACTIVITIES])
        {
            if (mavc.appliedLabels && (mavc.appliedLabels.count > 0))
            {
                self.activityEvent.userActivityLabels = [NSSet setWithArray: [NSMutableArray arrayWithArray:[mavc.appliedLabels allObjects]]];
            }
            else
            {
                self.activityEvent.userActivityLabels = nil;
            }
            NSLog(@"==== set the user activities to: %@",self.activityEvent.userActivityLabels);
        }
        else if ([mavc.category isEqualToString:MOOD])
        {
            NSLog(@"=== back from select mood applied labels: %@" , mavc.appliedLabels);
            if (mavc.appliedLabels && (mavc.appliedLabels.count > 0))
            {
                self.activityEvent.mood = (NSString *)[NSMutableArray arrayWithArray:[mavc.appliedLabels allObjects]];
            }
            else
            {
                self.activityEvent.mood = nil;
            }
            NSLog(@"=== set the mood to: %@",self.activityEvent.mood);
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
