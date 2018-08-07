//
//  PreviewView.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/22.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "PreviewView.h"

@implementation PreviewView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session
{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    self.videoPreviewLayer.session = session;
}

@end
