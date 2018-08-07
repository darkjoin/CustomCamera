//
//  SaveButton.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/26.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "SaveButton.h"

@implementation SaveButton

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint center = CGPointMake(CGRectGetWidth(rect)/2, CGRectGetHeight(rect)/2);
    CGFloat radius = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 2;
    
    CGContextAddArc(context, center.x, center.y, radius, 0, M_PI * 2, 1);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    
    CGContextMoveToPoint(context, radius * 0.5, radius);
    CGContextAddLineToPoint(context, radius, radius * 1.4);
    CGContextAddLineToPoint(context, radius * 1.6, radius * 0.6);

    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
    CGContextSetLineWidth(context, 5.0);
    CGContextStrokePath(context);
}

@end
