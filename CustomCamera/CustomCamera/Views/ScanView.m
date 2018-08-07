//
//  ScanView.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/24.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "ScanView.h"

@implementation ScanView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadScanLine];
    }
    
    return self;
}

- (void)loadScanLine
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 1.0)];
        lineView.backgroundColor = [UIColor greenColor];
        [self addSubview:lineView];
        
        [UIView animateWithDuration:3.0 animations:^{
            lineView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, 2.0);
        } completion:^(BOOL finished) {
            [lineView removeFromSuperview];
        }];
    }];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // draw bounds
    CGContextAddRect(context, self.bounds);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextStrokePath(context);
    
    // draw corners
    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
    CGContextSetLineWidth(context, 5.0);
    
    // upper left corner
    CGContextMoveToPoint(context, 0, 30);
    CGContextAddLineToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 30, 0);
    CGContextStrokePath(context);
    
    // upper right corner
    CGContextMoveToPoint(context, rect.size.width - 30, 0);
    CGContextAddLineToPoint(context, rect.size.width, 0);
    CGContextAddLineToPoint(context, rect.size.width, 30);
    CGContextStrokePath(context);
    
    // lower right corner
    CGContextMoveToPoint(context, rect.size.width, rect.size.height - 30);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width - 30, rect.size.height);
    CGContextStrokePath(context);
    
    // lower left corner
    CGContextMoveToPoint(context, 30, rect.size.height);
    CGContextAddLineToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, 0, rect.size.height - 30);
    CGContextStrokePath(context);    
}

@end
