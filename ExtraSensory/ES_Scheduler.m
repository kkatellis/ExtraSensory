//
//  ES_Scheduler.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/30/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_Scheduler.h"
#import "ES_AppDelegate.h"
#import "ES_SensorManager.h"
#import "ES_DataBaseAccessor.h"
#import "ES_NetworkAccessor.h"

@implementation ES_Scheduler

@synthesize sensorManager = _sensorManager;

@synthesize networkAccessor = _networkAccessor;

@synthesize databaseAccessor = _databaseAccessor;

@synthesize networkQueue = _networkQueue;

@synthesize dispatchQueue = _dispatchQueue;

- (ES_SensorManager *) sensorManager
{
    if (!_sensorManager)
    {
        _sensorManager = [ES_SensorManager new] ;
    }
    return _sensorManager;
}
- (ES_NetworkAccessor *) networkAccessor
{
    if (!_networkAccessor)
    {
        _networkAccessor = [ES_NetworkAccessor new] ;
    }
    return _networkAccessor;
}
- (ES_DataBaseAccessor *) databaseAccessor
{
    if (!_databaseAccessor)
    {
        _databaseAccessor = [ES_DataBaseAccessor new] ;
    }
    return _databaseAccessor;
}
- (NSMutableArray *) networkQueue
{
    if (!_networkQueue)
    {
        _networkQueue = [NSMutableArray new] ;
    }
    return _networkQueue;
}
/*- (dispatch_queue_t) dispatchQueue
{
    if (!_dispatchQueue)
    {
        _dispatchQueue = dispatch_queue_create( "ES_Scheduler Queue", DISPATCH_QUEUE_SERIAL );
    }
    return _dispatchQueue;
}*/



- (void) sampleSaveSend
{
    self.dispatchQueue = dispatch_queue_create("ES_Serial Queue", DISPATCH_QUEUE_SERIAL);
    
    __block ES_Scheduler *blockSelf = self;
    
    dispatch_sync( blockSelf.dispatchQueue, ^
                  {
                      [blockSelf.sensorManager record];
                  });
    
    
    dispatch_sync( blockSelf.dispatchQueue, ^
                  {
                      [ES_DataBaseAccessor zipSensorData];
                  });
    dispatch_sync( blockSelf.dispatchQueue, ^
                  {
                      [blockSelf.networkAccessor upload];
                  });
}

@end
