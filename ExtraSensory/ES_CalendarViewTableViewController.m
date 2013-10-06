//
//  ES_CalendarViewTableViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/3/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_CalendarViewTableViewController.h"
#import "ES_AppDelegate.h"
#import "ES_FeedbackViewController.h"
#import "ES_User.h"
#import "ES_ActivityStatistic.h"
#import "ES_DataBaseAccessor.h"

@interface ES_CalendarViewTableViewController ()

@property (nonatomic, weak)  ES_User *user;

@end

@implementation ES_CalendarViewTableViewController

@synthesize predictions = _predictions;

- (ES_User *)user
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.user;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ES_AppDelegate *appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.predictions = appDelegate.predictions;
    
    
    
    
    
    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.user addObserver: self
                forKeyPath: @"activities"
                   options: NSKeyValueObservingOptionNew
                   context: NULL];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.user removeObserver: self
                   forKeyPath:@"activities"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( [keyPath isEqualToString: @"activities"] )
    {
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

/*- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
    
     double now = [[NSDate date] timeIntervalSince1970];
     double historyAgeInSeconds = now - [self.user.activityStatistics.timeSamplingBegan doubleValue];
     double historyAgeInDays = historyAgeInSeconds / (60 * 60 * 24);
     return (int)ceil(historyAgeInDays);
}*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
     self.predictions = appDelegate.predictions;
    
    NSLog( @"prediction count = %d", [self.user.activities count]);
    return [self.predictions count];
    
    //return [appDelegate.user.activities count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.predictions = appDelegate.predictions;
    
    static NSString *CellIdentifier = @"ActivityDescription";
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [self.predictions objectAtIndex: indexPath.row ];
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



#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [(ES_FeedbackViewController *)segue.destinationViewController setFromCell:sender ];
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}



@end
