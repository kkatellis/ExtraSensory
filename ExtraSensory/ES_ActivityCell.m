//
//  ES_ActivityCell.m
//  ExtraSensory
//
//  Created by Arya Iranmehr on 7/21/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ActivityCell.h"
#import "ES_Activity.h"
#import "ES_Format.h"

@interface ES_ActivityCell ()

@property (nonatomic, strong) UIView *borderView;

@end

@implementation ES_ActivityCell

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame
{
    
    
    self = [super initWithFrame:frame];
    if (self) {
        
        self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.layer.shouldRasterize = YES;
        
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(0.0, 4.0);
        self.layer.shadowRadius = 5.0;
        self.layer.shadowOpacity = 0.0;
        
        self.borderView = [UIView new];
        [self.contentView addSubview:self.borderView];
        
        self.title = [UILabel new];
        self.title.numberOfLines = 0;
        self.title.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.title];
        
        self.time = [UILabel new];
        self.time.numberOfLines = 0;
        self.time.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.time];
        
        [self updateColors];
        
        CGFloat borderWidth = 2.0;
        CGFloat contentMargin = 2.0;
        UIEdgeInsets contentPadding = UIEdgeInsetsMake(1.0, (borderWidth + 4.0), 1.0, 4.0);
        
        [self.borderView makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(self.height);
            make.width.equalTo(@(borderWidth));
            make.left.equalTo(self.left);
            make.top.equalTo(self.top);
        }];
        
        [self.title makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.top).offset(contentPadding.top);
            make.left.equalTo(self.left).offset(contentPadding.left);
            make.right.equalTo(self.right).offset(-contentPadding.right);
        }];
        
        [self.time makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.title.bottom).offset(contentMargin-0.0);
            make.left.equalTo(self.left).offset(contentPadding.left -33);
            make.right.equalTo(self.right).offset(-contentPadding.right);
            make.bottom.lessThanOrEqualTo(self.bottom).offset(-contentPadding.bottom );
        }];
    }
    return self;
}

#pragma mark - UICollectionViewCell

- (void)setSelected:(BOOL)selected
{
    if (selected && (self.selected != selected)) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformMakeScale(1.025, 1.025);
            self.layer.shadowOpacity = 0.2;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.transform = CGAffineTransformIdentity;
            }];
        }];
    } else if (selected) {
        self.layer.shadowOpacity = 0.2;
    } else {
        self.layer.shadowOpacity = 0.0;
    }
    [super setSelected:selected]; // Must be here for animation to fire
    [self updateColors];
}

#pragma mark - ES_ActivityCell

- (void)setActivity:(ES_Activity *)activity
{
     self.color= [UIColor blueColor];
//    self.color= [ES_Format colorForActivity:activity.];
    [self updateColors];
    _activity=activity;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm"];
    if (_isDailyView) {
        self.time.attributedText =  [[NSAttributedString alloc] initWithString:@"" attributes:[self titleAttributesHighlighted:self.selected]];
        self.title.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:[self titleAttributesHighlighted:self.selected]];
    } else {
        self.time.attributedText =  [[NSAttributedString alloc] initWithString:[dateFormatter stringFromDate:_activity.startTime] attributes:[self titleAttributesHighlighted:self.selected]];
        self.time.font=[UIFont systemFontOfSize:9.0]; self.time.textColor=[UIColor blackColor];
        
        if (_activity.userCorrection) {
            self.title.attributedText = [[NSAttributedString alloc] initWithString:_activity.userCorrection attributes:[self titleAttributesHighlighted:self.selected]];
        } else if (_activity.serverPrediction){
            self.title.attributedText = [[NSAttributedString alloc] initWithString:_activity.serverPrediction attributes:[self titleAttributesHighlighted:self.selected]];
        }else{
            self.title.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:[self titleAttributesHighlighted:self.selected]];
        }
        
    }
    
}

- (void)updateColors
{
    self.contentView.backgroundColor = [self backgroundColorHighlighted:self.selected];
    self.borderView.backgroundColor = [self borderColor];
    self.title.textColor = [self textColorHighlighted:self.selected];
//    self.time.textColor = [self textColorHighlighted:self.selected];
    self.time.font=[UIFont systemFontOfSize:9.0];self.time.textColor=[UIColor blackColor];

}

- (NSDictionary *)titleAttributesHighlighted:(BOOL)highlighted
{
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.hyphenationFactor = 1.0;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    return @{
             NSFontAttributeName : [UIFont boldSystemFontOfSize:12.0],
             NSForegroundColorAttributeName : [self textColorHighlighted:highlighted],
             NSParagraphStyleAttributeName : paragraphStyle
             };
}

- (NSDictionary *)subtitleAttributesHighlighted:(BOOL)highlighted
{
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.hyphenationFactor = 1.0;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    return @{
             NSFontAttributeName : [UIFont systemFontOfSize:12.0],
             NSForegroundColorAttributeName : [self textColorHighlighted:highlighted],
             NSParagraphStyleAttributeName : paragraphStyle
             };
}

- (UIColor *)backgroundColorHighlighted:(BOOL)selected
{
    return selected ? self.color : [self.color colorWithAlphaComponent:0.2];
}

- (UIColor *)textColorHighlighted:(BOOL)selected
{
    //    return selected ? [UIColor whiteColor] : [UIColor blackColor];
    return selected ? [UIColor whiteColor] : self.color;
}

- (UIColor *)borderColor
{
    return [[self backgroundColorHighlighted:NO] colorWithAlphaComponent:1.0];
}

@end
