//
//  ES_ActiveFeedbackViewController.m
//  ExtraSensory
//
//  Created by Kat Ellis on 2/10/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ActiveFeedbackViewController.h"
#import "ES_MainActivityViewController.h"
#import "ES_DataBaseAccessor.h"

#define MAIN_ACTIVITY @"Main Activity"
#define SECONDARY_ACTIVITIES @"Secondary Activities"
#define MOOD @"Mood"
#define SUBMIT_FEEDBACK @"Submit Feedback"

@interface ES_ActiveFeedbackViewController ()

@property NSMutableArray *mainActivity;
@property NSMutableArray *secondaryActivities;
@property NSMutableArray *mood;

@end

@implementation ES_ActiveFeedbackViewController

- (IBAction)Cancel:(UIBarButtonItem *)sender {
    NSLog(@"Cancel button was pressed");
    [ES_DataBaseAccessor deleteActivity:self.activity];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@synthesize activity = _activity;

- (ES_Activity *) activity
{
    if (!_activity)
    {
        _activity = [ES_DataBaseAccessor newActivity];
    }
    return _activity;
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
    NSLog(@"Active Feedback View Did Load");
    
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


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:MAIN_ACTIVITY];
        cell.textLabel.text = MAIN_ACTIVITY;
        cell.detailTextLabel.text = [self.mainActivity componentsJoinedByString:@", "];
    }
    else if (indexPath.section == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SECONDARY_ACTIVITIES];
        cell.textLabel.text = SECONDARY_ACTIVITIES;
        cell.detailTextLabel.text = [self.secondaryActivities componentsJoinedByString:@", "];
    }
    else if (indexPath.section == 2)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:MOOD];
        cell.textLabel.text = MOOD;
        cell.detailTextLabel.text = [self.mood componentsJoinedByString:@", "];
    }
    else if (indexPath.section == 3)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SUBMIT_FEEDBACK];
        cell.textLabel.text = SUBMIT_FEEDBACK;
    }
    
    // Configure the cell...
    
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
    if (indexPath.section == 3)
    {
        [self SubmitFeedback];
    }
}

- (void) SubmitFeedback
{
    NSLog(@"Submit Feedback");
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    //[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:MAIN_ACTIVITY])
    {
        ES_MainActivityViewController *viewController = [segue destinationViewController];
        [viewController setAppliedLabels: [NSMutableSet setWithArray:self.mainActivity]];
        [viewController setChoices: @[@"LYING DOWN", @"SITTING", @"STANDING", @"WALKING", @"RUNNING", @"BICYCLING", @"DRIVING"]]; //replace with [newObject mainActivities];
    }
    else if ([segue.identifier isEqualToString:SECONDARY_ACTIVITIES])
    {
        ES_MainActivityViewController *viewController = [segue destinationViewController];
        [viewController setAppliedLabels: [NSMutableSet setWithArray:self.secondaryActivities]];
        [viewController setChoices: @[@"EATING", @"LISTENING TO MUSIC", @"HOUSEHOLD ACTIVITY"]];
    }
    else if ([segue.identifier isEqualToString:MOOD])
    {
        ES_MainActivityViewController *viewController = [segue destinationViewController];
        [viewController setAppliedLabels: [NSMutableSet setWithArray:self.mood]];
        [viewController setChoices: @[@"HAPPY", @"SAD", @"BORED", @"EXCITED"]];
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

-(IBAction)editedLabels:(UIStoryboardSegue *)segue
{
    NSLog(@"editedLabels: %@", segue.identifier);
    if ([segue.sourceViewController isKindOfClass:[ES_MainActivityViewController class]])
    {
        ES_MainActivityViewController *mavc = (ES_MainActivityViewController*)segue.sourceViewController;
        if ([segue.identifier isEqualToString:MAIN_ACTIVITY])
        {
            self.mainActivity = [NSMutableArray arrayWithArray:[mavc.appliedLabels allObjects]];
        }
        else if ([segue.identifier isEqualToString:SECONDARY_ACTIVITIES])
        {
            self.secondaryActivities = [NSMutableArray arrayWithArray:[mavc.appliedLabels allObjects]];
        }
        else if ([segue.identifier isEqualToString:MOOD])
        {
            self.mood = [NSMutableArray arrayWithArray:[mavc.appliedLabels allObjects]];
        }
    }
}


@end
