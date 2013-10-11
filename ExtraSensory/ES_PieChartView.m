//
//  ES_PieChartView.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/9/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_PieChartView.h"

@implementation ES_PieChartView

@synthesize activityCounts = _activityCounts;

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


#define DEFAULT_SCALE 0.90

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
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
    
    [self drawPieGraphAtPoint:midPoint withRadius:size andPercentages: self.activityPercentages inContext:context];
    
    
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
        if ( [m intValue] > 0 )
        {
            percentages = [percentages arrayByAddingObject: [NSNumber numberWithDouble: [m doubleValue] / total ] ];
        }
    }
    return percentages;
}

- (void)drawPieGraphAtPoint:(CGPoint)p withRadius:(CGFloat)radius andPercentages:(NSArray *)percentages inContext:(CGContextRef)context
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
    
    
}






@end
