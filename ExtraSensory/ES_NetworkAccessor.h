//
//  ES_NetworkAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ES_NetworkAccessor : NSObject

@property (strong, nonatomic) NSMutableData *recievedData;

@property (strong, nonatomic) NSMutableArray *predictions;

- (void) upload;
- (void) sendFeedback: (NSString *)feedback;

@end
