//
//  ViewController.m
//  XYPieChart
//
//  Created by XY Feng on 2/24/12.
//  Copyright (c) 2012 Xiaoyang Feng. All rights reserved.
//

#import "ES_NewPieViewController.h"
#import "ES_DataBaseAccessor.h"
#import "ES_ActivitiesStrings.h"
#import <QuartzCore/QuartzCore.h>

@implementation ES_NewPieViewController

@synthesize pieChart = _pieChart;
@synthesize selectedSliceLabel = _selectedSlice;
@synthesize slices = _slices;
@synthesize sliceColors = _sliceColors;
@synthesize sliceNames = _sliceNames;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    //NSLog(@"NewPieViewController did load");
    [super viewDidLoad];
    
    [self getActivityCounts];
    
    [self.pieChart setDataSource:self];
    [self.pieChart setStartPieAngle:M_PI_2];
    [self.pieChart setAnimationSpeed:0.5];
    [self.pieChart setLabelRadius:0];
    [self.pieChart setShowPercentage:NO];
    [self.pieChart setPieBackgroundColor:[UIColor colorWithWhite:0.95 alpha:1]];
    [self.pieChart setUserInteractionEnabled:YES];
    //[self.pieChart setLabelShadowColor:[UIColor blackColor]];
    [self.pieChart setDelegate:self];
    [self.pieChart setPieCenter:CGPointMake(self.pieChart.center.x, 180)];
    //[self.pieChart setLabelColor:[UIColor blackColor]];
    [self.pieChart setPieRadius:100];

}

- (void) getActivityCounts
{
    NSMutableDictionary *activityCounts = [ES_DataBaseAccessor getTodaysCounts];
    NSArray *activityNames = [ES_ActivitiesStrings mainActivities];
    //NSArray *colors = [ES_ActivitiesStrings mainActivitiesColors];
    self.slices = [NSMutableArray arrayWithCapacity:[activityCounts count]];
    self.sliceNames = [NSMutableArray arrayWithCapacity:[activityCounts count]];
    self.sliceColors = [NSMutableArray arrayWithCapacity:[activityCounts count]];
    for (NSString *act in activityNames)
    {
        [self.slices addObject:activityCounts[act]];
        [self.sliceNames addObject:act];
        [self.sliceColors addObject:[ES_ActivitiesStrings getColorForMainActivity:act]];
    }
}

- (void)viewDidUnload
{
    [self setPieChart:nil];
    [self setSelectedSliceLabel:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self getActivityCounts];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.pieChart reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    // Return YES for supported orientations
//    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
//}

//- (IBAction)SliceNumChanged:(id)sender
//{
//    UIButton *btn = (UIButton *)sender;
//    NSInteger num = [self.slices count];
//    if(btn.tag == 100 && num > -10)
//        num = num - ((num == 1)?2:1);
//    if(btn.tag == 101 && num < 10)
//        num = num + ((num == -1)?2:1);
//    
//}
//
//- (IBAction)clearSlices {
//    [_slices removeAllObjects];
//    [self.pieChart reloadData];
//}
//- (IBAction)updateSlices
//{
//    for(int i = 0; i < _slices.count; i ++)
//    {
//        [_slices replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:rand()%60+20]];
//    }
//    [self.pieChart reloadData];
//}

//- (IBAction)showSlicePercentage:(id)sender {
//    UISwitch *perSwitch = (UISwitch *)sender;
//    [self.pieChart setShowPercentage:perSwitch.isOn];
//}

#pragma mark - XYPieChart Data Source

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart
{
    return self.slices.count;
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
    return [[self.slices objectAtIndex:index] intValue];
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
    return [self.sliceColors objectAtIndex:(index % self.sliceColors.count)];
}

#pragma mark - XYPieChart Delegate
- (void)pieChart:(XYPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index
{
    //NSLog(@"will select slice at index %d",index);
}
- (void)pieChart:(XYPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index
{
   // NSLog(@"will deselect slice at index %d",index);
}
- (void)pieChart:(XYPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index
{
   // NSLog(@"did deselect slice at index %d",index);
    self.selectedSliceLabel.text = @"";
    self.selectedSliceLabel2.text = @"";
}
- (void)pieChart:(XYPieChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index
{
   // NSLog(@"did select slice at index %d",index);
    NSString* labelString = [NSString stringWithFormat:@"%@", [self.sliceNames objectAtIndex:index
                                                               ]];
    NSString* labelString2;
    if ([[self.slices objectAtIndex:index] integerValue] == 1) {
        labelString2 = @"1 minute";
    } else {
        labelString2 = [NSString stringWithFormat:@"%@ minutes", [self.slices objectAtIndex:index] ];
    }
    //NSLog(@"%@", labelString);
    self.selectedSliceLabel.text = labelString;
    self.selectedSliceLabel2.text = labelString2;
}

@end