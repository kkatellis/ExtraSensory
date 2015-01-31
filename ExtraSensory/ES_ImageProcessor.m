//
//  ES_ImageProcessor.m
//  ExtraSensory
//
//  Created by yonatan vaizman on 1/27/15.
//  Copyright (c) 2015 Bryan Grounds. All rights reserved.
//

#import "ES_ImageProcessor.h"

@interface ES_ImageProcessor()

@property (nonatomic,retain) AVCaptureSession *session;
@property (nonatomic,retain) NSMutableDictionary *features;

@property (nonatomic) NSNumber *pixelFormatType;
@property (nonatomic) BOOL finishedFrontCamera;

@end

@implementation ES_ImageProcessor

@synthesize pixelFormatType = _pixelFormatType;


- (NSString *) cameraNameForPosition:(AVCaptureDevicePosition)position {
    switch (position) {
        case AVCaptureDevicePositionFront:
            return @"front";
            break;
        case AVCaptureDevicePositionBack:
            return @"back";
            break;
            
        default:
            return nil;
            break;
    }
}

- (NSString *) cameraNameForCycleState {
    return [self cameraNameForPosition:[self desiredPosition]];
}

- (AVCaptureDevicePosition) desiredPosition {
    if (self.finishedFrontCamera) {
        return AVCaptureDevicePositionBack;
    }
    else {
        return AVCaptureDevicePositionFront;
    }
//    switch (_cameraSource) {
//        case ES_CameraSourceFront:
//            return AVCaptureDevicePositionFront;
//        case ES_CameraSourceBack:
//            return AVCaptureDevicePositionBack;
//        default:
//            return AVCaptureDevicePositionUnspecified;
//    }
}

- (void) startCameraCycle {
    self.features = [NSMutableDictionary dictionaryWithCapacity:2];
    self.finishedFrontCamera = NO;
    if (![self takePictureAndProcessIfPossible]) {
        // Then failed with front camera. Try back camera:
        self.finishedFrontCamera = YES;
        [self takePictureAndProcessIfPossible];
    }
}

- (BOOL) takePictureAndProcessIfPossible {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        NSLog(@"[imageProcessor] Can't use camera when app is in background");
        return NO;
    }
    
    @try {
        return [self takePictureAndProcess];
    }
    @catch (NSException *exception) {
        NSLog(@"[imageProcessor] Failed to capture image features");
        return NO;
    }
}

- (BOOL) takePictureAndProcess {
    // Look for the desired camera in all the video devices:
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *camera = nil;
    for (AVCaptureDevice *device in devices) {
        if (device.position == [self desiredPosition]) {
            camera = device;
            break;
        }
    }
    
    // In case not found, don't do anything:
    if (!camera) {
        return NO;
    }
    
    // Configure input camera:
    NSError *error = nil;
    if ([camera lockForConfiguration:&error]) {
        if ([camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            camera.focusMode = AVCaptureFocusModeAutoFocus;
        }
        if ([camera isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            camera.exposureMode = AVCaptureExposureModeAutoExpose;
        }
        if ([camera hasFlash] && [camera isFlashModeSupported:AVCaptureFlashModeOff]) {
            camera.flashMode = AVCaptureFlashModeOff;
        }
        if ([camera hasTorch] && [camera isTorchModeSupported:AVCaptureTorchModeOff]) {
            camera.torchMode = AVCaptureTorchModeOff;
        }
        
        [camera unlockForConfiguration];
    }
    else {
        NSLog(@"[ImageProcessor] Failed to lock %@ camera for configuration. Error: %@",[self cameraNameForPosition:camera.position], error);
        return NO;
    }
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    if (!deviceInput) {
        NSLog(@"[imageProcessor] Failed to create a device input. Error: %@",error);
        return NO;
    }
    
    // The image output:
    AVCaptureStillImageOutput *imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSArray *availableFormats = [imageOutput availableImageDataCVPixelFormatTypes];
    if (![self selectPixelFormatTypeFromAvailableTypes:availableFormats]) {
        NSLog(@"[imageProcessor] Couldn't find supported pixel format in the device's available formats");
        return NO;
    }
    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:self.pixelFormatType};
    [imageOutput setOutputSettings:outputSettings];
    
    // Combine componenets in a session:
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    }
    
    if ([self.session canAddInput:deviceInput]) {
        [self.session addInput:deviceInput];
    }
    else {
        NSLog(@"[imageProcessor] Can't add device input.");
        return NO;
    }
    
    if ([self.session canAddOutput:imageOutput]) {
        [self.session addOutput:imageOutput];
    }
    else {
        NSLog(@"[imageProcessor] Can't add image output.");
        return NO;
    }
    [self.session commitConfiguration];
    
    // Start the session:
    [self.session startRunning];
    
    // Create a connection:
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in imageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    if (!videoConnection) {
        NSLog(@"[imageProcessor] Failed to find appropriate connection");
        [self.session stopRunning];
        return NO;
    }
    
    // Ask for the capture:
    [imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
     ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (error) {
            NSLog(@"[imageProcessor] Capture request completed with error: %@",error);
            return;
        }
        [self handleCapturedData:imageDataSampleBuffer];
    } ];
     
    
    return YES;
    
}

- (BOOL) selectPixelFormatTypeFromAvailableTypes:(NSArray *)availableTypes
{
    NSArray *supportedTypes = @[[NSNumber numberWithInt:kCVPixelFormatType_24RGB],
                                [NSNumber numberWithInt:kCVPixelFormatType_24BGR],
                                [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]];
    
    for (NSNumber *supportedType in supportedTypes) {
        for (NSNumber *availableType in availableTypes) {
            if ([supportedType isEqualToNumber:availableType]) {
                self.pixelFormatType = supportedType;
                return YES;
            }
        }
    }
    
    return NO;
}

- (size_t) getRedComponentShift {
    switch ([self.pixelFormatType intValue]) {
        case kCVPixelFormatType_24RGB:
            return 0;
        case kCVPixelFormatType_24BGR:
            return 2;
        case kCVPixelFormatType_32BGRA:
            return 2;
        default:
            NSLog(@"[imageProcessor] Got unsupported pixel format type: %@",self.pixelFormatType);
            return 0;
    }
}

- (size_t) getGreenComponentShift {
    switch ([self.pixelFormatType intValue]) {
        case kCVPixelFormatType_24RGB:
            return 1;
        case kCVPixelFormatType_24BGR:
            return 1;
        case kCVPixelFormatType_32BGRA:
            return 1;
        default:
            NSLog(@"[imageProcessor] Got unsupported pixel format type: %@",self.pixelFormatType);
            return 0;
    }
    
}

- (size_t) getBlueComponentShift {
    switch ([self.pixelFormatType intValue]) {
        case kCVPixelFormatType_24RGB:
            return 2;
        case kCVPixelFormatType_24BGR:
            return 0;
        case kCVPixelFormatType_32BGRA:
            return 0;
        default:
            NSLog(@"[imageProcessor] Got unsupported pixel format type: %@",self.pixelFormatType);
            return 0;
    }
    
}

- (void) handleCapturedData:(CMSampleBufferRef)imageSampleBuffer {
    UIImage *image = [self imageFromSampleBuffer:imageSampleBuffer];
    NSLog(@"[imageProcessor] Took snapshot from %@ camera to calculate image-features from",[self cameraNameForCycleState]);
    [self.session stopRunning];
    [self calculateFeaturesForImage:image];
    
//    if (!self.finishedFrontCamera) {
//        // Then right now we are done with front camera. Lets move to the back:
//        self.finishedFrontCamera = YES;
//        NSLog(@"[imageProcessor] Done with front camera. Moving to back camera");
//        [self takePictureAndProcessIfPossible];
//    }
}

- (void) calculateFeaturesForImage:(UIImage *)image {
    
    CGImageRef cgimage = image.CGImage;
    size_t width = CGImageGetWidth(cgimage);
    size_t height = CGImageGetHeight(cgimage);
    size_t num_pixels = width * height;
    
    size_t bits_per_pixel = CGImageGetBitsPerPixel(cgimage);
    size_t bytes_per_pixel = bits_per_pixel / 8;
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgimage);
    CFDataRef dataCopy = CGDataProviderCopyData(dataProvider);
    const UInt8 *pixelData = CFDataGetBytePtr(dataCopy);
    
    size_t redShift = [self getRedComponentShift];
    size_t greenShift = [self getGreenComponentShift];
    size_t blueShift = [self getBlueComponentShift];
    
    // Prepare features to calculate:
    double sum_red = 0.;
    double sum_green = 0.;
    double sum_blue = 0.;
    double sum_brightness = 0.;

    double max_red = 0.;
    double max_green = 0.;
    double max_blue = 0.;
    double max_brightness = 0.;

    double min_red = 255.;
    double min_green = 255.;
    double min_blue = 255.;
    double min_brightness = 255.;
    
    double sum_sq_red = 0.;
    double sum_sq_green = 0.;
    double sum_sq_blue = 0.;
    double sum_sq_brightness = 0.;
    
    for (size_t pixel_i = 0; pixel_i < num_pixels; pixel_i ++) {
        size_t pixel_offset = pixel_i*bytes_per_pixel;
        UInt8 i_red = pixelData[pixel_offset+redShift];
        UInt8 i_green = pixelData[pixel_offset+greenShift];
        UInt8 i_blue = pixelData[pixel_offset+blueShift];
        
        double red = (double)i_red;
        double green = (double)i_green;
        double blue = (double)i_blue;
        double brightness = [self brightnessFromRed:red green:green blue:blue];
        
        // Update the cummulative features:
        sum_red += red;
        sum_green += green;
        sum_blue += blue;
        sum_brightness += brightness;
        
        max_red = (red > max_red) ? red : max_red;
        max_green = (green > max_green) ? green : max_green;
        max_blue = (blue > max_blue) ? blue : max_blue;
        max_brightness = (brightness > max_brightness) ? brightness : max_brightness;
        
        min_red = (red < min_red) ? red : min_red;
        min_green = (green < min_green) ? green : min_green;
        min_blue = (blue < min_blue) ? blue : min_blue;
        min_brightness = (brightness < min_brightness) ? brightness : min_brightness;
        
        sum_sq_red += red*red;
        sum_sq_green += green*green;
        sum_sq_blue += blue*blue;
        sum_sq_brightness += brightness*brightness;
    }
    
    // The features:
    double avr_red = sum_red / num_pixels;
    double avr_green = sum_green / num_pixels;
    double avr_blue = sum_blue / num_pixels;
    double avr_brightness = sum_brightness / num_pixels;
    
    double std_red = sqrt((sum_sq_red/num_pixels) - (avr_red*avr_red));
    double std_green = sqrt((sum_sq_green/num_pixels) - (avr_green*avr_green));
    double std_blue = sqrt((sum_sq_blue/num_pixels) - (avr_blue*avr_blue));
    double std_brightness = sqrt((sum_sq_brightness/num_pixels) - (avr_brightness*avr_brightness));
    
    NSMutableDictionary *cameraFeatures = [NSMutableDictionary dictionaryWithCapacity:17];
    
    [cameraFeatures setValue:[NSNumber numberWithUnsignedLong:num_pixels] forKey:@"num_pixels"];
    
    [cameraFeatures setValue:[NSNumber numberWithDouble:avr_red] forKey:@"avr_red"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:avr_green] forKey:@"avr_green"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:avr_blue] forKey:@"avr_blue"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:avr_brightness] forKey:@"avr_brightness"];
    
    [cameraFeatures setValue:[NSNumber numberWithDouble:max_red] forKey:@"max_red"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:max_green] forKey:@"max_green"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:max_blue] forKey:@"max_blue"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:max_brightness] forKey:@"max_brightness"];
    
    [cameraFeatures setValue:[NSNumber numberWithDouble:min_red] forKey:@"min_red"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:min_green] forKey:@"min_green"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:min_blue] forKey:@"min_blue"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:min_brightness] forKey:@"min_brightness"];
     
    [cameraFeatures setValue:[NSNumber numberWithDouble:std_red] forKey:@"std_red"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:std_green] forKey:@"std_green"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:std_blue] forKey:@"std_blue"];
    [cameraFeatures setValue:[NSNumber numberWithDouble:std_brightness] forKey:@"std_brightness"];
    
    [self.features setValue:cameraFeatures forKey:[NSString stringWithFormat:@"%@_camera",[self cameraNameForCycleState]]];
    
    NSLog(@"[imageProcessor] Added image features from %@ camera.",[self cameraNameForCycleState]);
}

- (double) brightnessFromRed:(double)red green:(double)green blue:(double)blue {
    return 0.299*red + 0.587*green + 0.114*blue;
}


- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferRef pixelBuffer = imageBuffer;
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}


- (NSDictionary *) outputMeasurements {
    return self.features;
}

- (void) stopSession {
    [self.session stopRunning];
    self.features = nil;//[[NSMutableDictionary alloc] initWithCapacity:17];
}

@end
