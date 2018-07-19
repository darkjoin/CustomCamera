//
//  PhotoButton.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/19.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "PhotoButton.h"

@implementation PhotoButton

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint center = CGPointMake(CGRectGetWidth(rect)/2, CGRectGetHeight(rect)/2);
    CGFloat radius = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 2;
    
    CGContextAddArc(context, center.x, center.y, radius, 0, M_PI * 2, 1);
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillPath(context);
    
    CGContextAddArc(context, center.x, center.y, radius * 0.8, 0, M_PI * 2, 1);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
}

@end
