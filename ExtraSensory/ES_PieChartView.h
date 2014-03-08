//
//  ES_PieChartView.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/9/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ES_PieChartView : UIView {
    
}

@property (nonatomic, assign) CGFloat circleRadius;
@property (nonatomic, retain) NSArray *sliceArray;
@property (nonatomic, retain) NSArray *colorsArray;

@property NSArray *activityPercentages;

@property NSArray *activityCounts;

@end
