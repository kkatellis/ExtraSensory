//
//  ES_Scheduler.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/30/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ES_SensorManager, ES_DataBaseAccessor, ES_NetworkAccessor;

@interface ES_Scheduler : NSObject

@property (nonatomic, strong) ES_SensorManager *sensorManager;

@property (nonatomic, strong) ES_NetworkAccessor *networkAccessor;

@property (nonatomic, strong) ES_DataBaseAccessor *databaseAccessor;

@property (nonatomic, strong) NSMutableArray *networkQueue;

@property (atomic, strong) dispatch_queue_t dispatchQueue;


- (void) sampleSaveSend;

@end
