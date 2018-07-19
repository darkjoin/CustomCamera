//
//  RewindButton.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/19.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "RewindButton.h"

@implementation RewindButton

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint center = CGPointMake(CGRectGetWidth(rect)/2, CGRectGetHeight(rect)/2);
    CGFloat radius = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 2;
    
    CGMutablePathRef trianglePath = CGPathCreateMutable();
    
    // draw triangle
    CGPathMoveToPoint(trianglePath, NULL, center.x, center.y);
    CGPathAddLineToPoint(trianglePath, NULL, center.x, center.y - radius * 0.3);
    CGPathAddLineToPoint(trianglePath, NULL, center.x - radius * 0.4, center.y);
    CGPathAddLineToPoint(trianglePath, NULL, center.x, center.y + radius * 0.3);
    CGPathCloseSubpath(trianglePath);
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(radius * 0.4 - 2.0, 0);
    CGMutablePathRef transformPath = CGPathCreateMutableCopyByTransformingPath(trianglePath, &translation);
    
    CGContextAddPath(context, trianglePath);
    CGContextAddPath(context, transformPath);
    
    CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    CGContextFillPath(context);
    
    CGPathRelease(trianglePath);
    CGPathRelease(transformPath);
    
    //    CGContextMoveToPoint(context, center.x, center.y);
    //    CGContextAddLineToPoint(context, center.x, center.y - radius * 0.3);
    //    CGContextAddLineToPoint(context, center.x - radius * 0.4, center.y);
    //    CGContextAddLineToPoint(context, center.x, center.y + radius * 0.3);
    //    CGContextAddLineToPoint(context, center.x, center.y);
    //    CGContextAddLineToPoint(context, center.x + radius * 0.4, center.y + radius * 0.3);
    //    CGContextAddLineToPoint(context, center.x + radius*0.4, center.y - radius*0.3);
    //    CGContextMoveToPoint(context, center.x, center.y);
    //
    //    CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    //    CGContextFillPath(context);
}

@end
