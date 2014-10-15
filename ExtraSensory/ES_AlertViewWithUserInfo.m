//
//  ES_AlertViewWithUserInfo.m
//  ExtraSensory
//
//  Created by yonatan vaizman on 8/2/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_AlertViewWithUserInfo.h"

@implementation ES_AlertViewWithUserInfo

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate userInfo:(NSDictionary *)userInfo cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    self = [super initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles, nil];
    self.userInfo = userInfo;
    
    return self;
}


@end
