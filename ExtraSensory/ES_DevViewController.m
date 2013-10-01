//
//  ES_DevViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_DevViewController.h"

#import "ES_SensorManager.h"

#import "ES_DataBaseAccessor.h"

#import "ES_Sample.h"

#import "ES_AppDelegate.h"

#import "ES_NetworkAccessor.h"

#import "ES_Scheduler.h"

@interface ES_DevViewController()

@property (nonatomic, strong) ES_Scheduler *scheduler;



@end

@implementation ES_DevViewController

@synthesize scheduler = _scheduler;

- (ES_Scheduler *) scheduler
{
    if (!_scheduler)
    {
        _scheduler = [ES_Scheduler new];
    }
    return _scheduler;
}

- (ES_SensorManager *)sensorManager
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.sensorManager;
}

- (IBAction)sendDataToServerButton:(UIButton *)sender
{
    NSLog( @"sendDataToServerButton");
    
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.networkAccessor upload];
}


- (IBAction)record:(UIButton *)sender
{
    NSLog( @"recordButton");
    
    [self.sensorManager record];
    
}

- (IBAction)printAllRecordedDataToTerminal:(UIButton *)sender {
    
    
    NSArray *arr;
    
    arr = [ES_DataBaseAccessor read: @"ES_Sample"];
    
    int n = 0;
    
    self.textView.text = @"";
    
    for (ES_Sample *s in arr)
    {
        self.textView.text = [self.textView.text stringByAppendingString: [s description]];
        NSLog( @" %.4f, %.4f, %.4f, .4f, %.4f, %.4f, %.4f, %.4f", s.acc_x, s.acc_y, s.acc_z, s.time, s.gyro_x, s.gyro_y, s.gyro_z );
        NSLog( @" %.4f, %.4f, %.4f, .4f, %.4f, %.4f, %.4f, %.4f", s.acc_x, s.acc_y, s.acc_z, s.time, s.gyro_x, s.gyro_y, s.gyro_z );
        n++;
    }
    
    //self.textView.text = [[NSNumber numberWithInt:n] description];
}
- (IBAction)testTextNZip:(UIButton *)sender
{
    [ES_DataBaseAccessor zipData];
}

- (IBAction)runSchedule:(UIButton *)sender
{
    
}
- (IBAction)runSchedulerSwitch:(UISwitch *)sender
{
    if (sender.isEnabled)
    {
        [self.scheduler sampleSaveSendCycler: self ];
    }
    else
    {
        NSLog( @"off!");
        exit(0);
    }
    
}


@end
