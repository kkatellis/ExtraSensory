//
//  ES_SettingsTableViewController.m
//  ExtraSensory
//
//  Created by Katherine Ellis on 4/27/15.
//  Copyright (c) 2015 Bryan Grounds. All rights reserved.
//

#import "ES_SettingsTableViewController.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_Settings.h"
#import "ES_NetworkAccessor.h"

@interface ES_SettingsTableViewController ()
@property BOOL showHomeLatLon;
@property (strong, nonatomic) ES_AppDelegate* appDelegate;
@end

@implementation ES_SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    if ([self.appDelegate.user.settings.hideHome boolValue]) {
        self.showHomeLatLon = TRUE;
    } else {
        self.showHomeLatLon = FALSE;
    }
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.tableView reloadData];//table was filled in viewDidLoad.
}

- (ES_AppDelegate *) appDelegate
{
    if (!_appDelegate)
    {
        _appDelegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return 3;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        if (self.showHomeLatLon) {
            return 3;
        } else {
            return 1;
        }
    } else if (section == 3) {
        return 1;
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:  indexPath];
            cell.textLabel.text = @"Data Collection";
            UISwitch *toggleSwitch = [[UISwitch alloc] init];
            cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
            [cell.accessoryView addSubview:toggleSwitch];
            toggleSwitch.on = self.appDelegate.userSelectedDataCollectionOn;
            toggleSwitch.tag = 0;
            [toggleSwitch addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        } else if (indexPath.row == 1) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"disclosureCell" forIndexPath:  indexPath];
            cell.textLabel.text = @"Reminder Interval";
            NSNumber *reminderIntervalMins = [NSNumber numberWithInteger:([self.appDelegate.user.settings.timeBetweenUserNags integerValue])/60];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ min", reminderIntervalMins];
        } else if (indexPath.row == 2) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:  indexPath];
            cell.textLabel.text = @"Secure Communication";
            UISwitch *toggleSwitch = [[UISwitch alloc] init];
            cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
            [cell.accessoryView addSubview:toggleSwitch];
            toggleSwitch.on = self.appDelegate.networkAccessor.useHTTPS;
            toggleSwitch.tag = 3;
            [toggleSwitch addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        }
    } else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath: indexPath];
        cell.textLabel.text = @"Home Sensing";
        UISwitch *toggleSwitch = [[UISwitch alloc] init];
        cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
        [cell.accessoryView addSubview:toggleSwitch];
        toggleSwitch.on = [self.appDelegate.user.settings.homeSensingParticipant boolValue];
        toggleSwitch.tag = 1;
        [toggleSwitch addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];

    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath: indexPath];
            cell.textLabel.text = @"Hide Home Location";
            UISwitch *toggleSwitch = [[UISwitch alloc] init];
            cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
            [cell.accessoryView addSubview:toggleSwitch];
            toggleSwitch.on = [self.appDelegate.user.settings.hideHome boolValue];
            toggleSwitch.tag = 2;
            [toggleSwitch addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath: indexPath];
            
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
            //textField.adjustsFontSizeToFitWidth = YES;
            textField.textColor = [UIColor blackColor];
            textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            textField.returnKeyType = UIReturnKeyDone;
            textField.backgroundColor = [UIColor whiteColor];
            textField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
            [textField setDelegate:self];
            //textField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
            [textField setEnabled: YES];
            textField.textAlignment = kCTRightTextAlignment;
            
            cell.accessoryView = textField;
            [textField addTarget:self action:@selector(editingEnded:) forControlEvents:UIControlEventEditingDidEnd];
            
            if (indexPath.row == 1) {
                cell.textLabel.text = @"Latitude";
                textField.tag = 0;
                textField.placeholder = [NSString stringWithFormat:@"%@", self.appDelegate.user.settings.homeLat];
            } else if (indexPath.row == 2) {
                cell.textLabel.text = @"Longitude";
                textField.tag = 1;
                textField.placeholder = [NSString stringWithFormat:@"%@", self.appDelegate.user.settings.homeLon];
            }
            
        }
    } else if (indexPath.section == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"redCell" forIndexPath: indexPath];
        cell.textLabel.text = self.appDelegate.user.uuid;
    }
    
    return cell;
}
- (IBAction)editingEnded:(UITextField*)textField {
    if (textField.tag == 0) {
        self.appDelegate.user.settings.homeLat = @([textField.text doubleValue]);
        NSLog(@"latEditingDidEnd: %@", self.appDelegate.user.settings.homeLat);
    } else if (textField.tag == 1) {
        self.appDelegate.user.settings.homeLon = @([textField.text doubleValue]);
        NSLog(@"lonEditingDidEnd: %@", self.appDelegate.user.settings.homeLon);
    }
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)updateSwitchAtIndexPath:(UISwitch *)aswitch{
    NSLog(@"updateSwitch");
    if (aswitch.tag == 0) {
        // data collection switch
        [self turnOnOffDataCollection:aswitch.on];
    } else if (aswitch.tag == 1) {
        // home sensing switch
        self.appDelegate.user.settings.homeSensingParticipant = [NSNumber numberWithBool:aswitch.on];
    } else if (aswitch.tag == 2) {
        // home hiding switch
        self.appDelegate.user.settings.hideHome = [NSNumber numberWithBool:aswitch.on];
        self.showHomeLatLon = aswitch.on;
        [self.tableView reloadData];
    } else if (aswitch.tag == 3) {
        self.appDelegate.networkAccessor.useHTTPS = aswitch.on;
    }
}

- (void) turnOnOffDataCollection:(BOOL)on{
    if (on)
    {
        BOOL isDataCollectionReallyStarting = [self.appDelegate userTurnedOnDataCollection];
        if (!isDataCollectionReallyStarting)
        {
            // Then user selected to activate the data collection mechanizm but probably there are too many zip files already in storage.
            NSString *message = @"Data collection is still inactive since the storage is in full capacity right now (until WiFi is available).";
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ExtraSensory" message:message delegate:self cancelButtonTitle:@"o.k." otherButtonTitles: nil];
            [alert show];
        }
    }
    else
    {
        [self.appDelegate userTurnedOffDataCollection];
    }
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self performSegueWithIdentifier:@"segueToLocation" sender:_reminderInterval];
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
