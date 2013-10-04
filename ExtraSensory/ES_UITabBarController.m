//
//  ES_UITabBarController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/3/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_UITabBarController.h"
#import "ES_AppDelegate.h"

@interface ES_UITabBarController ()

@end

@implementation ES_UITabBarController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"tabbarcontroller did load");
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog( @"Prepare for segue %@", segue );
    if ([segue.identifier isEqualToString:@"Calendar View"])
    {
        NSLog( @"segue identifier = Calendar View");
        ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [segue.destinationViewController setPredictions: appDelegate.predictions];
    }
}



@end
