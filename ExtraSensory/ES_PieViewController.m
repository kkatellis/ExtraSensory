//
//  ES_PieViewController.m
//  ExtraSensory
//
//  Created by Rafael Aguayo on 3/8/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_PieViewController.h"
#import "ES_ActivitiesStrings.h"
#import "ES_PieChartView.h"

@interface ES_PieViewController ()

//@property (weak, nonatomic) IBOutlet UILabel *border;
@property (weak, nonatomic) IBOutlet UILabel *legendColor0;
@property (weak, nonatomic) IBOutlet UILabel *legendColor1;
@property (weak, nonatomic) IBOutlet UILabel *legendColor2;
@property (weak, nonatomic) IBOutlet UILabel *legendColor3;
@property (weak, nonatomic) IBOutlet UILabel *legendColor4;
@property (weak, nonatomic) IBOutlet UILabel *legendColor5;
@property (weak, nonatomic) IBOutlet UILabel *legendColor6;

@property (nonatomic,retain) NSArray *legendColors;

@property (weak, nonatomic) IBOutlet UILabel *legendName0;
@property (weak, nonatomic) IBOutlet UILabel *legendName1;
@property (weak, nonatomic) IBOutlet UILabel *legendName2;
@property (weak, nonatomic) IBOutlet UILabel *legendName3;
@property (weak, nonatomic) IBOutlet UILabel *legendName4;
@property (weak, nonatomic) IBOutlet UILabel *legendName5;
@property (weak, nonatomic) IBOutlet UILabel *legendName6;

@property (nonatomic,retain) NSArray *legendNames;
@property (weak, nonatomic) IBOutlet ES_PieChartView *pieChartView;

@end



@implementation ES_PieViewController

@synthesize legendColors = _legendColors;
@synthesize legendNames = _legendNames;


- (NSArray *)legendColors
{
    if (!_legendColors)
    {
        _legendColors = [NSArray arrayWithObjects:self.legendColor0,self.legendColor1,self.legendColor2,self.legendColor3,self.legendColor4,self.legendColor5,self.legendColor6, nil];
    }
    
    return _legendColors;
}

- (NSArray *)legendNames
{
    if (!_legendNames)
    {
        _legendNames = [NSArray arrayWithObjects:self.legendName0,self.legendName1,self.legendName2,self.legendName3,self.legendName4,self.legendName5,self.legendName6, nil];
    }
    
    return _legendNames;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
//    self.border.layer.borderColor = [UIColor blackColor].CGColor;
//    self.border.layer.borderWidth = 3.0;
//    self.border.layer.cornerRadius = 5;
  
    NSArray *activityNames = [ES_ActivitiesStrings mainActivities];
    for (int ii=0; ii<7;ii ++)
    {
        UILabel *nameLabel = (UILabel *)[self.legendNames objectAtIndex:ii];
        UILabel *colorLabel = (UILabel *)[self.legendColors objectAtIndex:ii];
        
        NSString *activityName = (NSString *)[activityNames objectAtIndex:ii];
        UIColor *activityColor = [ES_ActivitiesStrings getColorForMainActivity:activityName];
        
        nameLabel.text = activityName;
        colorLabel.backgroundColor = activityColor;
        colorLabel.layer.cornerRadius = 10;
    }
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redrawPie) name:@"Activities" object:nil];
    [self redrawPie];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) redrawPie
{
    [self.pieChartView setNeedsDisplay];
    [self.pieChartView drawRect:self.pieChartView.frame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
