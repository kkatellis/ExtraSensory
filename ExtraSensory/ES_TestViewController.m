//
//  ES_ViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_TestViewController.h"

@interface ES_TestViewController ()


// UI Labels
@property (weak, nonatomic) IBOutlet UILabel *xAccLabel;
@property (weak, nonatomic) IBOutlet UILabel *yAccLabel;
@property (weak, nonatomic) IBOutlet UILabel *zAccLabel;


@end

@implementation ES_TestViewController


@synthesize xAccLabel;
@synthesize yAccLabel;
@synthesize zAccLabel;




- (IBAction)AccelerometerButton:(id)sender {
    
    NSLog(@"AccelerometerButton Pressed!");

}




- (IBAction)switch:(UISwitch *)sender {
    
    NSLog(@"Switch Switched!");

}


@end
