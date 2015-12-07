//
//  ES_NetworkAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ES_Activity.h"
#import "Reachability.h"

@interface ES_NetworkAccessor : NSObject{

NSURLConnection *api_connection;        // Connection to API server
Reachability *wifiReachable;     // Object for wifi reach testing
BOOL isReady;   //only upload one at a time
BOOL sendCycleOn;   //currently sending all saved data
    
}
@property (strong, nonatomic) NSMutableData *recievedData;
@property (strong, nonatomic) NSMutableArray *predictions;
@property (nonatomic) BOOL useHTTPS;

- (id)init;
- (void) upload;
- (void) sendNextFeedbackFromQueue;
- (void) sendFeedback: (ES_Activity *)feedback;
- (void) flush;

- (NetworkStatus) reachabilityStatus;

@end
