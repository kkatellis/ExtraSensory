//
//  ES_ImageProcessor.h
//  ExtraSensory
//
//  Created by yonatan vaizman on 1/27/15.
//  Copyright (c) 2015 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    ES_CameraSourceFront,
    ES_CameraSourceBack
} ES_CameraSource;

@interface ES_ImageProcessor : NSObject

@property (nonatomic) ES_CameraSource cameraSource;

- (id) initWithCameraSource:(ES_CameraSource)cameraSource;
- (BOOL) takePictureAndProcessIfPossible;
- (NSDictionary *) outputMeasurements;
- (void) stopSession;

@end
