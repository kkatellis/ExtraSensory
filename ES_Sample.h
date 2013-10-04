//
//  ES_Sample.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Activity;

@interface ES_Sample : NSManagedObject

@property (nonatomic, retain) NSNumber * acc_x;
@property (nonatomic, retain) NSNumber * acc_y;
@property (nonatomic, retain) NSNumber * acc_z;
@property (nonatomic, retain) NSNumber * gps_lat;
@property (nonatomic, retain) NSNumber * gps_long;
@property (nonatomic, retain) NSNumber * gps_speed;
@property (nonatomic, retain) NSNumber * gyro_x;
@property (nonatomic, retain) NSNumber * gyro_y;
@property (nonatomic, retain) NSNumber * gyro_z;
@property (nonatomic, retain) NSNumber * mic_avg_db;
@property (nonatomic, retain) NSNumber * mic_peak_db;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) ES_Activity *activity;

@end
