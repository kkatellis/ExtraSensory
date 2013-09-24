//
//  ES_SettingsViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_SettingsViewController.h"

@interface ES_SettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *enabledLabel;
@property (weak, nonatomic) IBOutlet UILabel *sampleFrequencyLabel;
@property Settings *settings;
@end

@implementation ES_SettingsViewController

@synthesize enabledLabel = _enabledLabel;
@synthesize sampleFrequencyLabel = _sampleFrequencyLabel;

- (IBAction)enabledSwitch:(UISwitch *)sender {
    if (sender.on)
    {
        self.enabledLabel.text = @"Enabled";
        
    }
    else
    {
        self.enabledLabel.text = @"Disabled";
    }
}

- (void)save
{
    ES_AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    
    self.settings = [NSEntityDescription insertNewObjectForEntityForName:@"Settings" inManagedObjectContext:moc];
    
    
    
}


/*- (void)save
{

    ES_AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *managedObjectContext = delegate.managedObjectContext;
    
    NSManagedObject *newSettings;
    
    newSettings = [NSEntityDescription insertNewObjectForEntityForName:@"Settings" inManagedObjectContext:managedObjectContext];

    [newSettings setValue:self.enabledLabel.text forKey:@""];
    
    NSError* error;
    [managedObjectContext save:&error];
    
    
}*/

@end
