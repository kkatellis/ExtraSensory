//
//  ES_SettingsTableViewController.m
//  ExtraSensory
//
//  Created by Katherine Ellis on 4/27/15.
//  Copyright (c) 2015 Bryan Grounds. All rights reserved.
//

#import "ES_SettingsTableViewController.h"
#import "ES_SettingsPickTableViewController.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_Settings.h"
#import "ES_NetworkAccessor.h"

#define MAIN_SECTION 0
#define HOME_SECTION 1
#define LOCATION_BUBBLE_SECTION 2
#define UUID_SECTION 3

#define DATA_COLLECTION_ROW 0
#define INTERVAL_ROW 1
#define STORED_SAMPLES_ROW 2
#define SECURE_ROW 3
#define CELLULAR_ROW 4

#define DATA_COLLECTION_TAG 0
#define HOME_SENSING_TAG 1
#define LOCATION_BUBBLE_TAG 2
#define HTTPS_TAG 3
#define CELLULAR_TAG 4

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
    if (section == MAIN_SECTION) {
        return 5;
    } else if (section == HOME_SECTION) {
        return 1;
    } else if (section == LOCATION_BUBBLE_SECTION) {
        if (self.showHomeLatLon) {
            return 3;
        } else {
            return 1;
        }
    } else if (section == UUID_SECTION) {
        return 1;
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    if (indexPath.section == MAIN_SECTION) {
        if (indexPath.row == DATA_COLLECTION_ROW) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:  indexPath];
            cell.textLabel.text = @"Data Collection";
            UISwitch *toggleSwitch = [[UISwitch alloc] init];
            cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
            [cell.accessoryView addSubview:toggleSwitch];
            toggleSwitch.on = self.appDelegate.userSelectedDataCollectionOn;
            toggleSwitch.tag = DATA_COLLECTION_TAG;
            [toggleSwitch addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        } else if (indexPath.row == INTERVAL_ROW) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"disclosureCell" forIndexPath:  indexPath];
            cell.textLabel.text = @"Reminder Interval";
            NSNumber *reminderIntervalMins = [NSNumber numberWithInteger:([self.appDelegate.user.settings.timeBetweenUserNags integerValue])/60];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ min", reminderIntervalMins];
        } else if (indexPath.row == STORED_SAMPLES_ROW){
            cell = [tableView dequeueReusableCellWithIdentifier:@"disclosureCell" forIndexPath:  indexPath];
            cell.textLabel.text = @"Samples to store";
            NSNumber *storedSamplesBeforeSend = [NSNumber numberWithInteger:[self.appDelegate.user.settings.storedSamplesBeforeSend integerValue]];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", storedSamplesBeforeSend];
        }else if (indexPath.row == SECURE_ROW) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:  indexPath];
            cell.textLabel.text = @"Secure Communication";
            UISwitch *toggleSwitch = [[UISwitch alloc] init];
            cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
            [cell.accessoryView addSubview:toggleSwitch];
            toggleSwitch.on = self.appDelegate.networkAccessor.useHTTPS;
            toggleSwitch.tag = HTTPS_TAG;
            [toggleSwitch addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        } else if (indexPath.row == CELLULAR_ROW) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
            cell.textLabel.text = @"Allow cellular communication";
            UISwitch *allowSwitch = [[UISwitch alloc] init];
            cell.accessoryView = [[UIView alloc] initWithFrame:allowSwitch.frame];
            [cell.accessoryView addSubview:allowSwitch];
            allowSwitch.on = [self.appDelegate.user.settings.allowCellular boolValue];
            allowSwitch.tag = CELLULAR_TAG;
            [allowSwitch addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        }
    } else if (indexPath.section == HOME_SECTION) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath: indexPath];
        cell.textLabel.text = @"Home Sensing";
        UISwitch *toggleSwitch = [[UISwitch alloc] init];
        cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
        [cell.accessoryView addSubview:toggleSwitch];
        toggleSwitch.on = [self.appDelegate.user.settings.homeSensingParticipant boolValue];
        toggleSwitch.tag = HOME_SENSING_TAG;
        [toggleSwitch addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];

    } else if (indexPath.section == LOCATION_BUBBLE_SECTION) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath: indexPath];
            cell.textLabel.text = @"Hide Home Location";
            UISwitch *toggleSwitch = [[UISwitch alloc] init];
            cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
            [cell.accessoryView addSubview:toggleSwitch];
            toggleSwitch.on = [self.appDelegate.user.settings.hideHome boolValue];
            toggleSwitch.tag = LOCATION_BUBBLE_TAG;
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
    } else if (indexPath.section == UUID_SECTION) {
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
    if (aswitch.tag == DATA_COLLECTION_TAG) {
        // data collection switch
        [self turnOnOffDataCollection:aswitch.on];
    } else if (aswitch.tag == HOME_SENSING_TAG) {
        // home sensing switch
        self.appDelegate.user.settings.homeSensingParticipant = [NSNumber numberWithBool:aswitch.on];
    } else if (aswitch.tag == LOCATION_BUBBLE_TAG) {
        // home hiding switch
        self.appDelegate.user.settings.hideHome = [NSNumber numberWithBool:aswitch.on];
        self.showHomeLatLon = aswitch.on;
        [self.tableView reloadData];
    } else if (aswitch.tag == HTTPS_TAG) {
        self.appDelegate.networkAccessor.useHTTPS = aswitch.on;
    } else if (aswitch.tag == CELLULAR_TAG) {
        self.appDelegate.user.settings.allowCellular = [NSNumber numberWithBool:aswitch.on];
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ExtraSensory" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"[settings] Preparing for segue");
    if ([segue.identifier isEqualToString:@"reminderSegue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ES_SettingsPickTableViewController *destViewController = segue.destinationViewController;
        destViewController.rowReceived = indexPath.row;
        NSLog(@"[settings] Set rowReceived to %d", (int)destViewController.rowReceived);
    }
}


@end
