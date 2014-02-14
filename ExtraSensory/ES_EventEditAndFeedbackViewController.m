//
//  ES_EventEditAndFeedbackViewController.m
//  ExtraSensory
//
//  Created by Yonatan Vaizman on 2/13/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_EventEditAndFeedbackViewController.h"

@interface ES_EventEditAndFeedbackViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UILabel *event1FromTime;
@property (weak, nonatomic) IBOutlet UILabel *event2FromTime;
@property (weak, nonatomic) IBOutlet UILabel *event2ToTime;
@property (weak, nonatomic) IBOutlet UIPickerView *event1Activity;

+ (NSArray *)activityLabelList;
+ (NSNumber *) indexOfActivityLabel:(NSString *)label;

@end

@implementation ES_EventEditAndFeedbackViewController

+ (NSArray *)activityLabelList
{
    static NSArray *labelList = nil;
    if (!labelList)
    {
        labelList = @[@"LyingDown",@"Sitting",@"Standing",@"Walking",@"Running",@"Bycicling",@"Driving"];
    }
    
    return labelList;
}

+ (NSNumber *) indexOfActivityLabel:(NSString *)label
{
    static NSMutableDictionary *activityLabelDict = nil;
    
    if (!activityLabelDict)
    {
        activityLabelDict = [[NSMutableDictionary alloc] init];
        NSArray * labelList = [self activityLabelList];
        for (int ii=1; ii < labelList.count; ii ++)
        {
            NSString * insertedLabel = (NSString *)labelList[ii];
            [activityLabelDict setValue:([NSNumber numberWithInt:ii]) forKey:insertedLabel];
        }
    }
    
    
    if ([[activityLabelDict allKeys] containsObject:label])
    {
        return activityLabelDict[label];
    }
    
    return 0;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    // Get the current info of the relevant activity event:
    NSDate * startDate = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.startTimestamp doubleValue]];
    NSDate * endDate = [NSDate dateWithTimeIntervalSince1970:[self.activityEvent.endTimestamp doubleValue]];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    NSString *dateString = [NSString stringWithFormat:@"%@ - ",[dateFormatter stringFromDate:startDate]];
    
    NSString *endTimeString = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:endDate]];
    
    // Edit the initial state of the labels to reflect the current info of the relevant activity event:
    self.event1FromTime.text = dateString;
    self.datePicker.date = endDate;
    self.datePicker.minimumDate = startDate;
    self.datePicker.maximumDate = endDate;
    NSString *currentActivityLabel = self.activityEvent.userCorrection ? self.activityEvent.userCorrection : self.activityEvent.serverPrediction;
    NSLog(@"===== %@" , currentActivityLabel);
    NSNumber *labelIndex = [[self class] indexOfActivityLabel:currentActivityLabel];
    [self.event1Activity selectRow:[labelIndex intValue] inComponent:0 animated:NO];
    
    
    self.event2FromTime.hidden = YES;
    self.event2ToTime.hidden = YES;
    self.event2ToTime.text = endTimeString;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return [self.class activityLabelList].count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return [self.class activityLabelList][row];
}
@end
