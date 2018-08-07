//
//  FocusView.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/30.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "FocusView.h"

@implementation FocusView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    
    CGContextStrokeRect(context, rect);
    
    CGFloat midX = CGRectGetWidth(rect)/2;
    CGFloat midY = CGRectGetHeight(rect)/2;
    CGFloat length = 5;
    
    CGContextMoveToPoint(context, midX, 0);
    CGContextAddLineToPoint(context, midX, length);
    
    CGContextMoveToPoint(context, midX * 2, midY);
    CGContextAddLineToPoint(context, midX * 2 - length, midY);
    
    CGContextMoveToPoint(context, midX, midY * 2);
    CGContextAddLineToPoint(context, midX, midY * 2 - length);
    
    CGContextMoveToPoint(context, 0, midY);
    CGContextAddLineToPoint(context, length, midY);
    
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokePath(context);
}


@end
