//
//  PreviewView.h
//  CustomCamera
//
//  Created by pro648 on 2018/7/22.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import <UIKit/UIKit.h>

@import AVFoundation;

@interface PreviewView : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureSession *session;

@end
