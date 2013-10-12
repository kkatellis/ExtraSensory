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
#import "ES_Activity.h"
#import "ES_CalendarViewCell.h"

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
    
    NSLog(@"activities = %@", [self.user.activities description]);
    NSLog(@"number of activities = %lu", (unsigned long)[self.user.activities count] );
    
    
    
    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:@"Activities" object:nil];

    [self.user addObserver: self
                forKeyPath: @"activities"
                   options: NSKeyValueObservingOptionNew
                   context: NULL];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.predictions = appDelegate.predictions;
    
    NSLog( @"prediction count = %lu", (unsigned long)[self.user.activities count]);
    return [self.predictions count];
    
    //return [appDelegate.user.activities count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.predictions = appDelegate.predictions;
    
    static NSString *CellIdentifier = @"ActivityDescription";
    
    
    ES_CalendarViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    NSTimeInterval t = [[(ES_Activity *)[appDelegate.predictions objectAtIndex: indexPath.row ] timestamp] doubleValue];

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    NSString *dateString = [NSString stringWithFormat: @"%@", [dateFormatter stringFromDate: [NSDate dateWithTimeIntervalSince1970: t ]]];
    

    
    cell.activity = [appDelegate.predictions objectAtIndex: indexPath.row];
    cell.textLabel.text = dateString;
    
    if (cell.activity.userCorrection)
    {
        cell.detailTextLabel.text = [[(ES_Activity *)[appDelegate.predictions objectAtIndex: indexPath.row ] userCorrection] stringByAppendingString:@"*"];
    }
    else
    {
        cell.detailTextLabel.text = [(ES_Activity *)[appDelegate.predictions objectAtIndex: indexPath.row ] serverPrediction];
    }
    
    return cell;
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [(ES_FeedbackViewController *)segue.destinationViewController setFromCell:sender ];
    [(ES_FeedbackViewController *)segue.destinationViewController setPredictions: self.predictions];
}



@end
