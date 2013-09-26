//
//  ES_ViewController.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_TestViewController.h"
#import "ES_Sensors.h"

@interface ES_TestViewController ()


// UI Labels
@property (weak, nonatomic) IBOutlet UILabel *xAccLabel;
@property (weak, nonatomic) IBOutlet UILabel *yAccLabel;
@property (weak, nonatomic) IBOutlet UILabel *zAccLabel;

@property NSTimer *timer;

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

- (IBAction)recordAccelerometerButton:(UIButton *)sender
{
    
    ES_Sensors *sensors = [[ES_Sensors alloc] init];
    
    
    // 1800 sec = 30 min * 60 sec.
    NSTimeInterval timeWindow = 5;
    NSLog(@"timeWindow : %f", timeWindow);
    
/*    + (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats*/
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timeWindow
                                                   target:sensors
                                                 selector:@selector(stopRecordingAccelerometer)
                                                 userInfo:nil
                                                 repeats:NO];
    
    [sensors startRecordingAccelerometer];

}

@end
