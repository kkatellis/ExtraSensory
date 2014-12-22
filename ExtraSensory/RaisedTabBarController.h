//
//  RaisedTabBarController.h
//  ExtraSensory
//
//  Created by Kat Ellis on 3/17/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RaisedTabBarController : UITabBarController

//-(void) addCenterButtonWithImage:(UIImage*)buttonImage highlightImage:(UIImage*)highlightImage;

-(void) disablePlusButton;
-(void) enablePlusButton;
//-(void) hidePlusButton;
//-(void) showPlusButton;
-(void) hideRecordingImage;
-(void) showRecordingImage;
-(void) checkIfRecordingOrNot;

@end
