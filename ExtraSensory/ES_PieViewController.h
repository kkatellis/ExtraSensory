//
//  ES_PieViewController.h
//  ExtraSensory
//
//  Created by Rafael Aguayo on 3/8/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYPieChart.h"

@interface ES_PieViewController : UIViewController <XYPieChartDelegate, XYPieChartDataSource>

@property (strong, nonatomic) IBOutlet XYPieChart *pieChartRight;
@property (strong, nonatomic) IBOutlet XYPieChart *pieChartLeft;
@property (strong, nonatomic) IBOutlet UILabel *percentageLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedSliceLabel;
@property (strong, nonatomic) IBOutlet UITextField *numOfSlices;
@property (strong, nonatomic) IBOutlet UISegmentedControl *indexOfSlices;
@property (strong, nonatomic) IBOutlet UIButton *downArrow;
@property(nonatomic, strong) NSMutableArray *slices;
@property(nonatomic, strong) NSArray        *sliceColors;

@end
