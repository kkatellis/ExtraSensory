//
//  ES_WelcomeViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_WelcomeViewController.h"
#import "ES_AppDelegate.h"


#import "ES_SensorManager.h"
#import "ES_AccelerometerAccessor.h"

#import "ES_DataBaseAccessor.h"

#import "Samples.h"
#import "AccelerometerData.h"

@interface ES_WelcomeViewController()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) ES_SensorManager *sensorManager;


//-(void) createDataWithKey: key AndValue: value;

@end

@implementation ES_WelcomeViewController

@synthesize sensorManager = _sensorManager;

- (ES_SensorManager *)sensorManager
{
    if (!_sensorManager)
    {
        _sensorManager = [[ES_SensorManager alloc] init];
    }
    return _sensorManager;
}

- (IBAction)record:(UIButton *)sender {
    
    [self.sensorManager.accelerometer record];
    
}

- (IBAction)printAllRecordedDataToTerminal:(UIButton *)sender {
    
    
    NSArray *arr;
    
    arr = [ES_DataBaseAccessor read: @"Samples"];
    
    int n = 0;
    
    for (Samples *s in arr)
    {
        n++;
        NSLog( @" %@, %@, %@, %@", s.accelerometerData.x, s.accelerometerData.y, s.accelerometerData.z, s.accelerometerData.time );
    }
    
    self.textView.text = [[NSNumber numberWithInt:n] description];
}



@end
