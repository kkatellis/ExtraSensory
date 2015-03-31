//
//  ES_WatchProcessor.h
//  ExtraSensory
//
//  Created by Rafael Aguayo on 3/31/15.
//  Copyright (c) 2015 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PebbleKit/PebbleKit.h>

@interface ES_WatchProcessor : NSObject

@property (nonatomic, strong) PBWatch *myWatch;

-(BOOL)receiveAccelDataFromWatch;




@end
