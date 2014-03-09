//
//  ES_SelectTimeViewController.h
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/24/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetTimeDelegate

- (void)receiveTime:(NSDate *)selectedTime for:(BOOL)startTime;
@end

@interface ES_SelectTimeViewController : UIViewController

@property (nonatomic) id<SetTimeDelegate> delegate;

@property (nonatomic) NSDate *selectedDate;
@property (nonatomic) NSDate *minDate;
@property (nonatomic) NSDate *maxDate;
@property (nonatomic) NSString *timeName;
@property (nonatomic) BOOL isStartTime;

@end
