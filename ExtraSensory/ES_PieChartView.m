//
//  ES_PieChartView.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/9/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_PieChartView.h"
#import "ES_AppDelegate.h"
#import "ES_ActivityStatistic.h"
#import "ES_User.h"

@implementation ES_PieChartView

@synthesize activityCounts = _activityCounts;
@synthesize circleRadius = _circleRadius;
@synthesize colorsArray = _colorsArray;
@synthesize sliceArray = _sliceArray;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.


#define DEFAULT_SCALE 1

- (void)drawRect:(CGRect)rect
{
    /*CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint midPoint;
    midPoint.x = self.bounds.origin.x + self.bounds.size.width/2;
    midPoint.y = self.bounds.origin.y + self.bounds.size.height/2;
    
    CGFloat size = self.bounds.origin.x + self.bounds.size.width/2;
    if (self.bounds.size.height < self.bounds.size.width) size = self.bounds.size.height / 2;
    size *= DEFAULT_SCALE;
    
    CGContextSetLineWidth(context, 1.0);
    [[UIColor blackColor] setStroke];
    
    
    self.activityPercentages = [self countsToPercentages: self.activityCounts];
    
    NSLog(@"Draw Pie Chart with percentages: %@", self.activityPercentages );
    
    [self drawPieGraphAtPoint:midPoint withRadius:size andPercentages: self.activityPercentages inContext:context];*/
    
    ES_AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    
    // Set up the slices
    /*NSArray *slices = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.4],
                       [NSNumber numberWithFloat:0.2],
                       [NSNumber numberWithFloat:0.1],
                       [NSNumber numberWithFloat:0.3],
                       nil];*/
    
    NSArray *slices = [NSArray arrayWithObjects:appDelegate.user.activityStatistics.countLying,appDelegate.user.activityStatistics.countSitting, appDelegate.user.activityStatistics.countStanding, appDelegate.user.activityStatistics.countWalking,appDelegate.user.activityStatistics.countRunning,appDelegate.user.activityStatistics.countBicycling,appDelegate.user.activityStatistics.countDriving, nil];
    
    self.sliceArray = slices;
    // Set up the colors for the slices
    NSArray *colors = [NSArray arrayWithObjects:(id)[UIColor purpleColor].CGColor,
                       (id)[UIColor blueColor].CGColor,
                       (id)[UIColor greenColor].CGColor,
                       (id)[UIColor yellowColor].CGColor,(id)[UIColor orangeColor].CGColor,(id)[UIColor redColor].CGColor,(id)[UIColor whiteColor].CGColor, nil];
    
    self.colorsArray = colors;
    
    self.sliceArray = [self countsToPercentages:slices];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self drawPieChart:context];
    
    
}

- (NSArray *) countsToPercentages: (NSArray *) counts
{
    NSArray *percentages = [NSArray new];
    
    int total = 0;
    
    
    for ( NSNumber *n in counts )
    {
        total += [n intValue];
    }
    
    for (NSNumber *m in counts)
    {
        if ( [m intValue] >= 0 )
        {
            percentages = [percentages arrayByAddingObject: [NSNumber numberWithDouble: [m doubleValue] / total ] ];
        }
    }
    return percentages;
}

- (void)drawPieChart:(CGContextRef)context  {
    CGPoint circleCenter = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    // Set the radius of your pie chart
    self.circleRadius = 125;
    
    for (int i = 0; i < [_sliceArray count]; i++) {
        
        // Determine start angle
        CGFloat startValue = 0;
        for (int k = 0; k < i; k++) {
            startValue += [[_sliceArray objectAtIndex:k] floatValue];
        }
        CGFloat startAngle = startValue * 2 * M_PI - M_PI/2;
        
        // Determine end angle
        CGFloat endValue = 0;
        for (int j = i; j >= 0; j--) {
            endValue += [[_sliceArray objectAtIndex:j] floatValue];
        }
        CGFloat endAngle = endValue * 2 * M_PI - M_PI/2;
        
        CGContextSetFillColorWithColor(context, (CGColorRef)[_colorsArray objectAtIndex:i]);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, circleCenter.x, circleCenter.y);
        CGContextAddArc(context, circleCenter.x, circleCenter.y, self.circleRadius, startAngle, endAngle, 0);
        CGContextClosePath(context);
        CGContextFillPath(context);
    }
}

/*- (void)drawPieGraphAtPoint:(CGPoint)p withRadius:(CGFloat)radius andPercentages:(NSArray *)percentages inContext:(CGContextRef)context
{
    NSLog(@"Draw Pie Chart with percentages: %@", percentages );
    UIGraphicsPushContext(context);
    
    NSArray *colors = [[NSArray alloc] initWithObjects: [UIColor purpleColor], [UIColor blueColor], [UIColor greenColor], [UIColor yellowColor], [UIColor orangeColor], [UIColor redColor], [UIColor whiteColor],nil];
    
    CGFloat startAngle;
    startAngle = 0;
    CGFloat endAngle = 2 * M_PI;
    
    int i = 0;
    
    if ( [percentages count] > 0 )
    {
        for ( i = 0; i < [percentages count]; i++ )
        {
            
            NSLog(@"i = %d, sA = %f, eA = %f", i, startAngle, endAngle );

            CGContextBeginPath(context);
            
            CGContextMoveToPoint(context, p.x, p.y);
            
            CGContextAddArc(context, p.x, p.y, radius, startAngle, endAngle, NO);
            
            CGContextClosePath(context);
            
            [ [colors objectAtIndex: i] setFill];
            [[UIColor blackColor] setStroke];
            
            CGContextDrawPath(context, kCGPathFillStroke);

            startAngle = (1.0 - [[percentages objectAtIndex:i ] doubleValue ]) * 2 * M_PI;
        }
    }
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, p.x, p.y);
    
    CGContextAddArc(context, p.x, p.y, radius, startAngle, endAngle, NO);
    
    CGContextClosePath(context);
    
    [ [colors objectAtIndex: i] setFill];
    [[UIColor blackColor] setStroke];
    
    CGContextDrawPath(context, kCGPathFillStroke);
    
    UIGraphicsPopContext();
    
    
}*/






@end
