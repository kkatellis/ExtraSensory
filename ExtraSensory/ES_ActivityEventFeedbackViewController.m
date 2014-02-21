//
//  ES_ActivityEventFeedbackViewController.m
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/14/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ActivityEventFeedbackViewController.h"


@interface ES_ActivityEventFeedbackViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *mainActivityCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *otherActivitiesCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *moodCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *startTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *endTimeCell;


@end

@implementation ES_ActivityEventFeedbackViewController

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
    // Get the current info of the relevant activity event:
    NSDate * startDate = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.startTimestamp doubleValue]];
    NSDate * endDate = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.endTimestamp doubleValue]];
    
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    NSString *startString = [dateFormatter stringFromDate:startDate];
    NSString *endString = [dateFormatter stringFromDate:endDate];
    
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
    NSLog(@"%@",indexPath);
    if (indexPath.section == 3)
    {
        [self submitFeedback];
    }
}

- (void) submitFeedback
{
    NSDate * startDateBeforeCahnge = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.startTimestamp doubleValue]];
    NSDate * endDateBeforeChange = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.endTimestamp doubleValue]];

    // Create an ES_Activity object for each minute in the original range:
    for (NSDate *time = startDateBeforeCahnge; [time compare:endDateBeforeChange] != NSOrderedDescending; time = [time dateByAddingTimeInterval:60])
    {
        
    }
    // Send the data to the server:
    /////////////
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
