//
//  RaisedTabBarController.m
//  ExtraSensory
//
//  Created by Kat Ellis on 3/17/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "RaisedTabBarController.h"
//#import "ES_ActiveFeedbackViewController.h"
#import "ES_FeedbackViewController.h"
#import "ES_AppDelegate.h"

#define PLUS_TAG 111
#define RECORDING_TAG 222

@interface RaisedTabBarController ()

@end

@implementation RaisedTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addCenterButtonWithImage:[UIImage imageNamed:@"text-plus-icon.png"] highlightImage:nil];
    [self addRecordingImage:[UIImage imageNamed:@"redCircle.png"]];
    [self checkIfRecordingOrNot];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)resizeImage:(UIImage *)image toHaveHeight:(CGFloat)newHeight
{
    CGFloat stretchRatio = newHeight / image.size.height;
    CGFloat newWidth = stretchRatio * image.size.width;
    CGSize newSize = CGSizeMake(newWidth, newHeight);
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0.0, 0.0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void) hideViewWithTag:(NSInteger)tag
{
    [[self.view viewWithTag:tag] setHidden:YES];
}

- (void) showViewWithTag:(NSInteger)tag
{
    [[self.view viewWithTag:tag] setHidden:NO];
    
}

- (void)hidePlusButton
{
    [self hideViewWithTag:PLUS_TAG];
}

- (void)showPlusButton
{
    [self showViewWithTag:PLUS_TAG];
}

- (void)hideRecordingImage
{
    [self hideViewWithTag:RECORDING_TAG];
}

- (void)showRecordingImage
{
    if (!self.view.hidden)
    {
        [self showViewWithTag:RECORDING_TAG];
    }
}

- (void)checkIfRecordingOrNot
{
    ES_AppDelegate *delegate = (ES_AppDelegate *)UIApplication.sharedApplication.delegate;
    if (delegate.recordingRightNow)
    {
        [self showRecordingImage];
    }
    else
    {
        [self hideRecordingImage];
    }
}

-(void) addRecordingImage:(UIImage*)recordingImage
{
    //begin tinting
//    UIGraphicsBeginImageContextWithOptions (recordingImage.size, NO, [[UIScreen mainScreen] scale]); // for correct resolution on retina, thanks @MobileVet
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    CGContextTranslateCTM(context, 0, recordingImage.size.height);
//    CGContextScaleCTM(context, 1.0, -1.0);
//
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:recordingImage];
//    NSLog(@"=== created imageView: %@ with image: %@",imageView,recordingImage);
    
    UIImage *newImage = [self resizeImage:recordingImage toHaveHeight:self.tabBar.frame.size.height/4.0];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:newImage];
    
    // Set the position of the recording image:
    UIView *plusView = [self.view viewWithTag:PLUS_TAG];
    CGFloat origin_y = plusView.frame.origin.y;
    CGFloat origin_x = plusView.frame.origin.x - newImage.size.width;
    CGRect newFrame = CGRectMake(origin_x, origin_y, newImage.size.width, newImage.size.height);
    imageView.frame = newFrame;

    imageView.tag=RECORDING_TAG; // "a" number for finding this image in subviews, (in order to hide it)
 
    [self.view addSubview:imageView];
}

-(void) addCenterButtonWithImage:(UIImage*)buttonImage highlightImage:(UIImage*)highlightImage
{
    //begin tinting
    UIGraphicsBeginImageContextWithOptions (buttonImage.size, NO, [[UIScreen mainScreen] scale]); // for correct resolution on retina, thanks @MobileVet
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, buttonImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    //CGRect rect = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
    
    // image drawing code here
    // draw tint color
    //CGContextSetBlendMode(context, kCGBlendModeNormal);
    //[[UIColor redColor] setFill];
    //CGContextFillRect(context, rect);
    
    // mask by alpha values of original image
    //CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
    //CGContextDrawImage(context, rect, buttonImage.CGImage);
    
    //buttonImage = UIGraphicsGetImageFromCurrentImageContext();
    //UIGraphicsEndImageContext();
    //end tinting
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    button.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    
    CGFloat heightDifference = buttonImage.size.height - self.tabBar.frame.size.height;
    if (heightDifference < 0)
        button.center = self.tabBar.center;
    else
    {
        CGPoint center = self.tabBar.center;
        center.y = center.y - heightDifference/2.0 + 0.5;
        button.center = center;
    }
    button.tag=PLUS_TAG; // "a" number for finding this button in subviews, (in order to hide it)
    
    [button addTarget:self
               action:@selector(activeFeedback:)
     forControlEvents:UIControlEventTouchUpInside];
    
    [button setTintColor:[UIColor redColor]];
    [self.view addSubview:button];
}

-(void) activeFeedback:(UIButton*)button
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"ActiveFeedback" bundle:nil];
    ES_FeedbackViewController *feedbackController = [storyboard instantiateViewControllerWithIdentifier:@"Feedback"];
    feedbackController.feedbackType = ES_FeedbackTypeActive;
    feedbackController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UINavigationController *nav = [UINavigationController new];
    [nav pushViewController:feedbackController animated:NO];
    [self presentViewController:nav animated:YES completion:nil];
//    ES_ActiveFeedbackViewController* initialView = [storyboard instantiateInitialViewController];
//    initialView.modalPresentationStyle = UIModalPresentationFormSheet;
//    [self presentViewController:initialView animated:YES completion:nil];
}

@end
