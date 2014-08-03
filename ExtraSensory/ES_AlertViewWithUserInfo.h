//
//  ES_AlertViewWithUserInfo.h
//  ExtraSensory
//
//  Created by yonatan vaizman on 8/2/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ES_AlertViewWithUserInfo : UIAlertView

@property (retain,nonatomic) NSDictionary *userInfo;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate userInfo:(NSDictionary *)userInfo cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;

@end
