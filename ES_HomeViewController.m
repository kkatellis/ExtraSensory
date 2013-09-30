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
#import "ES_SettingsModel.h"
#import "ES_DataBaseAccessor.h"

@interface ES_HomeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *sampleFrequencyLabel;

@property (weak, nonatomic) IBOutlet UISlider *sampleFrequencySlider;

@end

@implementation ES_HomeViewController

@synthesize settings = _settings;

- (ES_SettingsModel *) settings
{
    if (!_settings)
    {
        _settings = [ES_DataBaseAccessor newSettingsModel];
    }
    return _settings;
}

- (void) viewDidAppear:(BOOL)animated
{
    [self.settings addObserver:self
           forKeyPath:@"sampleFrequency"
              options:NSKeyValueObservingOptionNew
              context:NULL];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog( @"observing keyPath: %@ ofObject: %@", keyPath, [object valueForKey:@"sampleFrequency"]);
    
    if ( [keyPath isEqualToString: @"sampleFrequency"] )
        [self.sampleFrequencyLabel setText: [NSString stringWithFormat: @"%@", [object valueForKey:@"sampleFrequency"]] ];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.settings removeObserver:self forKeyPath:@"sampleFrequency"];
}

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
    //self.sampleFrequencyLabel.text = [NSString stringWithFormat: @"%.0f", sender.value ];
    self.sensorManager.sampleFrequency = self.sampleFrequencySlider.value;
    //NSLog( @"SliderValue = %.2f", self.sampleFrequencySlider.value);
    
    [self.settings setValue: [NSNumber numberWithFloat: sender.value ]
        forKeyPath: @"sampleFrequency"];
    
}


- (void)viewDidLoad
{
    self.sampleFrequencySlider.minimumValue = 1.0;
    self.sampleFrequencySlider.maximumValue = 100.0;
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
