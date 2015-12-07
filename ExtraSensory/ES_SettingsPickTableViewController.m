//
//  ES_SettingsPickTableViewController.m
//  ExtraSensory
//
//  Created by Katherine Ellis on 4/27/15.
//  Copyright (c) 2015 Bryan Grounds. All rights reserved.
//

#import "ES_SettingsPickTableViewController.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_Settings.h"

#define DATA_COLLECTION_ROW 0
#define INTERVAL_ROW 1
#define STORED_SAMPLES_ROW 2
#define SECURE_ROW 3
#define CELLULAR_ROW 4

@interface ES_SettingsPickTableViewController ()
@property (strong, nonatomic) ES_AppDelegate* appDelegate;
@end

@implementation ES_SettingsPickTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ES_AppDelegate *) appDelegate
{
    if (!_appDelegate)
    {
        _appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (NSArray *) reminderOptions{
    return @[@2, @5, @10, @20, @30];
}

- (NSArray *) storageOptions{
    return @[@1, @5, @10, @20, @30];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (self.rowReceived == INTERVAL_ROW){
        return [[self reminderOptions] count];
    } else if (self.rowReceived == STORED_SAMPLES_ROW){
        return [[self storageOptions] count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    if (self.rowReceived == INTERVAL_ROW){
        // Nag interval:
        int reminderIntervalMins = ([self.appDelegate.user.settings.timeBetweenUserNags integerValue]) / 60.0;
        // Configure the cell...
        NSNumber *mins = self.reminderOptions[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%ld min", (long)[mins integerValue]];
        
        if ([mins integerValue] == reminderIntervalMins) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
    } else if (self.rowReceived == STORED_SAMPLES_ROW){
        // storage
        int storedSamplesBeforeSend = (int)[self.appDelegate.user.settings.storedSamplesBeforeSend integerValue];
        // Configure the cell...
        NSNumber *num = self.storageOptions[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%ld", (long)[num integerValue]];
        
        if ([num integerValue] == storedSamplesBeforeSend) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (self.rowReceived == INTERVAL_ROW){
        // Nag interval:
        int mins = (int)[self.reminderOptions[indexPath.row] integerValue];
        self.appDelegate.user.settings.timeBetweenUserNags = [NSNumber numberWithInt:(mins * 60.0)];
        NSLog(@"reminder Interval = %@", self.appDelegate.user.settings.timeBetweenUserNags);
    } else if (self.rowReceived == STORED_SAMPLES_ROW){
        //storage
        int num = (int)[self.storageOptions[indexPath.row] integerValue];
        self.appDelegate.user.settings.storedSamplesBeforeSend = [NSNumber numberWithInt:num];
    }
    [tableView reloadData];
}
//-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
