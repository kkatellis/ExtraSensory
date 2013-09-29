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

#import "ES_DataBaseAccessor.h"

#import "ES_Sample.h"

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
    
    [self.sensorManager record];
    
}

- (IBAction)printAllRecordedDataToTerminal:(UIButton *)sender {
    
    
    NSArray *arr;
    
    arr = [ES_DataBaseAccessor read: @"ES_Sample"];
    
    int n = 0;
    
    for (ES_Sample *s in arr)
    {
        NSLog( @" %.4f, %.4f, %.4f, .4f, %.4f, %.4f, %.4f, %.4f", s.acc_x, s.acc_y, s.acc_z, s.time, s.gyro_x, s.gyro_y, s.gyro_z );
        NSLog( @" %.4f, %.4f, %.4f, .4f, %.4f, %.4f, %.4f, %.4f", s.acc_x, s.acc_y, s.acc_z, s.time, s.gyro_x, s.gyro_y, s.gyro_z );
        n++;
    }
    
    self.textView.text = [[NSNumber numberWithInt:n] description];
}



@end
