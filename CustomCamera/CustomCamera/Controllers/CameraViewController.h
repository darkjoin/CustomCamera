//
//  CameraViewController.h
//  CustomCamera
//
//  Created by pro648 on 2018/7/19.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@interface CameraViewController : UIViewController

@property (nonatomic, assign) AVCaptureDevicePosition currentCameraPosition;
@property (nonatomic, assign) AVCaptureFlashMode flashMode;

- (void)prepare;
- (void)displayPreviewOnView:(UIView *)view;
- (void)switchCameras;
- (void)capturePhoto;

@end
