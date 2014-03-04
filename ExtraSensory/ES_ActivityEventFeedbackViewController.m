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
//#import "ES_SelectTimeViewController.h"

#define MAIN_ACTIVITY_SEC (int)0
#define USER_ACTIVITIES_SEC (int)1
#define MOOD_SEC (int)2
#define TIMES_SEC (int)3
#define SEND_SEC (int)4

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
        NSLog(@"==== received time: %@. now starttime is: %@",selectedTime,self.startTime);
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
    NSLog(@"==== fb: viewWill. what is activity event: %@",self.activityEvent);
    NSLog(@"==== fb: start time reference is: %lu. and the date value is: %@",(uintptr_t)self.startTime,self.startTime);
    // Get the current info of the relevant activity event:
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    NSString *startString = [dateFormatter stringFromDate:self.startTime];
    NSString *endString = [dateFormatter stringFromDate:self.endTime];
    
    NSLog(@"====fb: viewWillAppear start: %@. end: %@",startString,endString);
    self.startTimeCell.detailTextLabel.text = startString;
    self.endTimeCell.detailTextLabel.text =
        endString;

    self.mainActivityCell.detailTextLabel.text = self.activityEvent.userCorrection ? self.activityEvent.userCorrection : self.activityEvent.serverPrediction;
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
    switch (indexPath.section) {
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
    
    NSLog(@"==== in settingTimeFor. selectTimeView is: %@",selectTimeView);
    NSLog(@"==== activity event is: %@ and its start time is: %@",self.activityEvent,self.activityEvent.startTimestamp);
    NSDate *tmp =[NSDate dateWithTimeIntervalSince1970:[self.activityEvent.startTimestamp doubleValue]];
    NSLog(@"==== tmp NSDate is: %@" ,tmp);
    selectTimeView.minDate = tmp;
    NSLog(@"==== after setting minDate");
    selectTimeView.maxDate = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.endTimestamp doubleValue]];
    
    NSLog(@"==== in settingTimeFor 2");
    
    selectTimeView.selectedDate = settingStartTime ? self.startTime : self.endTime;
    NSLog(@"==== 3. selectedRef is %lu and its val is: %@",(uintptr_t)selectTimeView.selectedDate,selectTimeView.selectedDate);
    selectTimeView.timeName = settingStartTime ? @"start" : @"end";

    selectTimeView.isStartTime = settingStartTime;
    selectTimeView.delegate = self;
    NSLog(@"==== 4");
    [self.navigationController pushViewController:selectTimeView animated:YES];
}

- (void) submitFeedback
{
    NSDate * startDateBeforeCahnge = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.startTimestamp doubleValue]];
    NSDate * endDateBeforeChange = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.endTimestamp doubleValue]];

    ES_AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];

    // Create an ES_Activity object for each minute in the original range:
    for (NSDate *time = startDateBeforeCahnge; [time compare:endDateBeforeChange] != NSOrderedDescending; time = [time dateByAddingTimeInterval:60])
    {
        // Create an object for this minute:
        ES_Activity *minuteActivity = [self.activityEvent.startActivity copy];
        minuteActivity.timestamp = [NSNumber numberWithInt:(int)[time timeIntervalSince1970]];
        
        // Is this minute now outside of the edited event's time period?
        if (([time compare:self.startTime] == NSOrderedAscending) || ([time compare:self.endTime] == NSOrderedDescending))
        {
            // Remove the userCorrection label, and leave the rest:
            minuteActivity.userCorrection = nil;
        }
        else
        {
            // Copy the chosen labels from the edited activity event:
            minuteActivity.userCorrection = self.activityEvent.userCorrection;
            minuteActivity.userActivityLabels = self.activityEvent.userActivityLabels;
        }
        // Send this minute's data to the server:
        [appDelegate.networkAccessor sendFeedback:minuteActivity];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
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
