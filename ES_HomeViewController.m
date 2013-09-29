//
//  ES_HomeViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/29/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_HomeViewController.h"
#import "ES_SensorManager.h"
#import "ES_AppDelegate.h"

@interface ES_HomeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *sampleFrequencyLabel;

@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;

@end

@implementation ES_HomeViewController

- (ES_SensorManager *)sensorManager
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.sensorManager;
}


- (IBAction)dataCollectionSwitch:(UISwitch *)sender
{
    if ( sender.isEnabled )
    {
        NSLog(@"This doesn't do anything yet...");
    }
}

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    self.sampleFrequencyLabel.text = [NSString stringWithFormat: @"%.0f", sender.value ];
    self.sensorManager.sampleFrequency = self.frequencySlider.value;
    NSLog( @"SliderValue = %.2f", self.frequencySlider.value);
}


- (void)viewDidLoad
{
    self.frequencySlider.minimumValue = 1.0;
    self.frequencySlider.maximumValue = 100.0;
    self.sampleFrequencyLabel.text = [NSString stringWithFormat: @"%.0f", self.sensorManager.sampleFrequency ];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
