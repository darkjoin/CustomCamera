//
//  StopButton.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/19.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "StopButton.h"

@implementation StopButton

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint center = CGPointMake(CGRectGetWidth(rect)/2, CGRectGetHeight(rect)/2);
    CGFloat radius = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 2;
    
    CGMutablePathRef circlePath = CGPathCreateMutable();
    CGPathAddArc(circlePath, NULL, center.x, center.y, radius * 0.4, 0, M_PI * 2, 1);
    CGPathRef roundedRectPath = CGPathCreateWithRoundedRect(CGPathGetBoundingBox(circlePath), 5, 5, NULL);
    CGContextAddPath(context, roundedRectPath);
    
    CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    CGContextFillPath(context);
    
    //    // create with bezier path
    //    CGMutablePathRef circlepath = CGPathCreateMutable();
    //    CGPathAddArc(circlepath, NULL, center.x, center.y, radius * 0.4, 0, M_PI * 2, 1);
    //    CGRect boundingBoxRect = CGPathGetBoundingBox(circlepath);
    //
    //    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:boundingBoxRect cornerRadius:5];
    //    [[UIColor redColor] setFill];
    //    [roundedRectPath fill];
}

@end
