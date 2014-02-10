//
//  ES_NetworkAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ES_Activity.h"

@interface ES_NetworkAccessor : NSObject{

NSURLConnection *api_connection;        // Connection to API server
    
}
@property (strong, nonatomic) NSMutableData *recievedData;

@property (strong, nonatomic) NSMutableArray *predictions;



- (void) upload;
- (void) sendFeedback: (ES_Activity *)feedback;

@end
