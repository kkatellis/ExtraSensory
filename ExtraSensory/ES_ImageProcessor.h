//
//  ES_ImageProcessor.h
//  ExtraSensory
//
//  Created by yonatan vaizman on 1/27/15.
//  Copyright (c) 2015 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface ES_ImageProcessor : NSObject


- (void) startCameraCycle;
- (NSDictionary *) outputMeasurements;
- (void) stopSession;

@end
