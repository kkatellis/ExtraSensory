//
//  ES_WelcomeViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_WelcomeViewController.h"
#import "ES_AppDelegate.h"
#import "Samples.h"
#import "AccelerometerData.h"

@interface ES_WelcomeViewController()

@property (weak, nonatomic) IBOutlet UILabel *display;
@property (weak, nonatomic) IBOutlet UITextField *textField;

//-(void) createDataWithKey: key AndValue: value;

@end

@implementation ES_WelcomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
}

/*- (IBAction)saveButton:(UIButton *)sender {
    NSString *date = [NSString stringWithFormat: @"%f",[[NSDate date] timeIntervalSince1970]];
    
    [self createDataWithKey: date AndValue: self.textField.text];
    
    
}

*/- (IBAction)loadButton:(UIButton *)sender {
    
    ES_AppDelegate *d = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = d.managedObjectContext;
    
    NSError *error = [[NSError alloc] init];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Samples" inManagedObjectContext:context];
    
    [request setEntity:entity];
    
    NSArray *arr = [context executeFetchRequest:request error:&error];
    
    //NSString *result = @"->";
    
    for (Samples *s in arr)
    {
        NSLog( @" %@, %@, %@, %@, %@", s.batchID, s.accelerometerData.x, s.accelerometerData.y, s.accelerometerData.z, s.accelerometerData.time );
    }
    
    //self.display.text = result;
    //self.textField.text = @"";
    
}

/*- (IBAction)textFieldAction:(UITextField *)sender
{
    
    ES_AppDelegate *d = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = d.managedObjectContext;
    
    NSError *error = [[NSError alloc] init];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AllSettings" inManagedObjectContext:context];
    
    [request setEntity:entity];
    
    NSArray *arr = [context executeFetchRequest:request error:&error];
    
    NSString *result = @"->";
    
    for (AllSettings *a in arr)
    {
        result = [result stringByAppendingString:a.settingName];
        result = [result stringByAppendingString:@": "];
        result = [result stringByAppendingString:a.settingState];
        result = [result stringByAppendingString:@", "];
    }
    
    self.display.text = result;
    self.textField.text = @"";
    
    
}

-(void) createDataWithKey: (NSString *)key AndValue:(NSString *)value
{
    ES_AppDelegate *d = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = d.managedObjectContext;
    
    AllSettings *allSettings = [NSEntityDescription insertNewObjectForEntityForName:@"AllSettings" inManagedObjectContext:context];
    
    allSettings.settingName = key;
    allSettings.settingState = value;
    
    NSError *error = [[NSError alloc] init];
    
    if (![context save:&error])
    {
        NSLog(@"Error, fool!");
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AllSettings" inManagedObjectContext:context];
    
    [request setEntity:entity];
    
    NSArray *arr = [context executeFetchRequest:request error:&error];
    
    for (AllSettings *a in arr)
    {
        NSLog(@"SettingName: %@", a.settingName);
        NSLog(@"SettingState: %@", a.settingState);
    }
}

-(void) find: (NSString *)key AndValue:(NSString *)value
{
    ES_AppDelegate *d = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = d.managedObjectContext;
    
    AllSettings *allSettings = [NSEntityDescription insertNewObjectForEntityForName:@"AllSettings" inManagedObjectContext:context];
    
    allSettings.settingName = key;
    allSettings.settingState = value;
    
    NSError *error = [[NSError alloc] init];
    
    if (![context save:&error])
    {
        NSLog(@"Error, fool!");
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AllSettings" inManagedObjectContext:context];
    
    [request setEntity:entity];
    
    NSArray *arr = [context executeFetchRequest:request error:&error];
    
    for (AllSettings *a in arr)
    {
        NSLog(@"SettingName: %@", a.settingName);
        NSLog(@"SettingState: %@", a.settingState);
    }
}*/



@end
