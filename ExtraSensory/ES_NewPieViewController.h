//
//  ViewController.h
//  XYPieChart
//
//  Created by XY Feng on 2/24/12.
//  Copyright (c) 2012 Xiaoyang Feng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYPieChart.h"

@interface ES_NewPieViewController : UIViewController <XYPieChartDelegate, XYPieChartDataSource>

@property (strong, nonatomic) IBOutlet XYPieChart *pieChart;
@property (strong, nonatomic) IBOutlet UILabel *selectedSliceLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedSliceLabel2;
@property(nonatomic, strong) NSMutableArray *slices;
@property(nonatomic, strong) NSMutableArray *sliceColors;
@property(nonatomic, strong) NSMutableArray *sliceNames;
@end