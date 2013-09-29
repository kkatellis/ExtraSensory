//
//  ES_Sample.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/29/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ES_Sample : NSManagedObject

@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic) double acc_x;
@property (nonatomic) double acc_y;
@property (nonatomic) double acc_z;
@property (nonatomic) double gyro_x;
@property (nonatomic) double gyro_y;
@property (nonatomic) double gyro_z;
@property (nonatomic) double gps_lat;
@property (nonatomic) double gps_long;
@property (nonatomic) double time;
@property (nonatomic) double mic_avg_db;
@property (nonatomic) double mic_peak_db;
@property (nonatomic) double gps_speed;

@end
