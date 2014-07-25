//
//  ES_ActivityCell.h
//  ExtraSensory
//
//  Created by Arya Iranmehr on 7/21/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ES_Activity;


@interface ES_ActivityCell : UICollectionViewCell
@property (nonatomic, weak) ES_Activity *activity;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *time;
@property (nonatomic, assign) BOOL isDailyView;
@end
