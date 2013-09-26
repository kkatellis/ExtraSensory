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
@property (weak, nonatomic) IBOutlet UISwitch *Switch;


- (void)saveSettingName: sN State: sS;

@end

@implementation ES_SettingsViewController

@synthesize enabledLabel = _enabledLabel;
@synthesize sampleFrequencyLabel = _sampleFrequencyLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)enabledSwitch:(UISwitch *)sender {
    if (sender.on)
    {
        self.enabledLabel.text = @"Enabled";
        [self saveSettingName: @"AccelerometerEnbaled" State:@"YES"];


    }
    else
    {
        self.enabledLabel.text = @"Disabled";
        [self saveSettingName: @"AccelerometerEnabled" State:@"NO"];
    }
}

- (void)saveSettingName: (NSString *)sN
                  State: (NSString *)sS
{
/*    ES_AppDelegate *delegate =  [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    
    Settings * settings = [NSEntityDescription insertNewObjectForEntityForName:@"AllSettings" inManagedObjectContext: moc];
    settings.
    settings.

    
    
    // Error Checking
    
    NSError *error;
    
    if(![moc save:&error])
        NSLog(@"__Something went wrong in the database!");
    
    
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AllSettings" inManagedObjectContext:moc];
    
    [request setEntity:entity];
    
    // SELECT all from PHONE
    NSArray *arr = [moc executeFetchRequest:request error:&error];
    
    for (Settings *s in arr)
    {
        NSLog(@"SettingName %@", s.);
        NSLog(@"SettingState %@", s.);
    }*/
}


@end
