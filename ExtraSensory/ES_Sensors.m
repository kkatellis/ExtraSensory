//
//  ES_Sensors.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/24/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_Sensors.h"
#import "ES_AppDelegate.h"
#import "AccelerometerData.h"
#import "Samples.h"
#import "Settings.h"


// Private interface
@interface ES_Sensors()

@property (strong, nonatomic) CMMotionManager *motion;
@property (weak, nonatomic) Samples *samples;
@property (weak, nonatomic) AccelerometerData *accelerometerData;
@property (strong, nonatomic) NSMutableArray *array;
@property (strong, nonatomic) NSString *batchID;


@end


@implementation ES_Sensors

@synthesize motion = _motion;
@synthesize frequency = _frequency;

-(NSNumber *)frequency
{
    if (!_frequency) _frequency = [NSNumber numberWithDouble: .05];
    return _frequency;
}

-(void)startRecordingAccelerometer
{
    
    ES_AppDelegate *d = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = d.managedObjectContext;
    
    self.samples = [NSEntityDescription insertNewObjectForEntityForName:@"Samples" inManagedObjectContext:context];
    
    self.motion.accelerometerUpdateInterval = [self.frequency doubleValue];
    
    NSString * timeMarker1;
    NSString * timeMarker2;
    
    self.array = [self.array initWithCapacity: 1000];
    
    ES_Sensors * __weak weakSelf = self;
    if ([weakSelf.motion isAccelerometerAvailable])
    {
        timeMarker1 = [NSString stringWithFormat: @"%f",[[NSDate date] timeIntervalSince1970]];
        weakSelf.batchID = [[d.uuid UUIDString] stringByAppendingString:timeMarker1];
        
        NSLog(@"start accelerometer updates @ %@", timeMarker1);

        if (![weakSelf.motion isAccelerometerActive])
        {
            [weakSelf.motion startAccelerometerUpdatesToQueue: [NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accData, NSError *error){
                
                Samples *s;
                s = [NSEntityDescription insertNewObjectForEntityForName:@"Samples" inManagedObjectContext:context];
                AccelerometerData *a;
                a = [NSEntityDescription insertNewObjectForEntityForName:@"AccelerometerData" inManagedObjectContext:context];
                s.accelerometerData = a;
                a.samples = s;
                
                s.accelerometerData.x = [NSNumber numberWithDouble: accData.acceleration.x];
                s.accelerometerData.y = [NSNumber numberWithDouble: accData.acceleration.y];
                s.accelerometerData.z = [NSNumber numberWithDouble: accData.acceleration.z];
                s.accelerometerData.time = [NSNumber numberWithDouble: accData.timestamp];
                
                s.batchID = [self.batchID copy];
                                
            }];
            
        }
        timeMarker2 = [NSString stringWithFormat: @"%f",[[NSDate date] timeIntervalSince1970]];
    }
    
    
/*    NSString * type = @"Accelerometer";
    NSNumber * freq = self.frequency;

        s.type = [type copy];
        s.sampleFrequency = [freq copy];
 */
    
    
    
    
    NSError *error = [[NSError alloc] init];
    
    if (![context save:&error])
    {
        NSLog(@"Error saving sample data!");
    }
    
/*    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Samples" inManagedObjectContext:context];
    
    [request setEntity:entity];
    
    NSArray *arr = [context executeFetchRequest:request error:&error];
    
    for (Samples *s in arr)
    {
        NSLog(@"SettingName: %@", s);
        NSLog(@"SettingState: %@", s);
    }*/

}



-(void)stopRecordingAccelerometer
{
    if ([self.motion isAccelerometerActive])
    {
        [self.motion stopAccelerometerUpdates];
        NSLog(@"stop accelerometer updates");
    }
    else
        NSLog(@"Accelerometer is already running!");
    
}

// Getter
- (CMMotionManager *)motion
{
    if (!_motion) _motion = [[CMMotionManager alloc] init];
    return _motion;
}




@end
