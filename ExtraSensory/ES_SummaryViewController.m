//
//  ES_SummaryViewController.m
//  ExtraSensory
//
//  Created by Kat Ellis on 3/12/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_SummaryViewController.h"
#import "ES_ActivitiesStrings.h"
#import "ES_DataBaseAccessor.h"
#import "ES_ContainerViewController.h"
#import "ES_NetworkAccessor.h"
#import "ES_AppDelegate.h"

@interface ES_SummaryViewController ()
@property (nonatomic, weak) ES_ContainerViewController *containerViewController;
@property (nonatomic, strong) NSMutableDictionary *activityCounts;

@end

@implementation ES_SummaryViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    self.activityCounts = [ES_DataBaseAccessor getTodaysCounts];
    [self.tableView reloadData];
    
    [(ES_AppDelegate *)[[UIApplication sharedApplication] delegate] logNetworkStackAndZipFiles];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[ES_ActivitiesStrings mainActivities] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Today's activity counts";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *activity = [[self.activityCounts allKeys] objectAtIndex:indexPath.row];
    cell.textLabel.text = activity;
    int mins = [self.activityCounts[activity] integerValue];
    NSString *activityDuration;
    if (mins >= 60)
    {
        int hrs = mins / 60;
        mins = mins - 60 * hrs;
        activityDuration = [NSString stringWithFormat:@"%d hr %d min", hrs, mins];
        
    } else {
        activityDuration = [NSString stringWithFormat:@"%d min", mins];
    }
    
    cell.detailTextLabel.text = activityDuration;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
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
