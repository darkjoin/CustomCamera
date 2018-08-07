//
//  CustomCameraDelegate.h
//  CustomCamera
//
//  Created by pro648 on 2018/8/3.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CustomCameraDelegate <NSObject>

@optional
- (void)prepareUIForChangingCaptureMode:(NSUInteger)captureMode;
- (void)prepareUIForSaving;

// capture photo
- (void)updateLivePhotoButtonStatus;
- (void)finishCapturePhotoWithPhotoData:(NSData *)photoData andWithLivePhotoFileURL:(NSURL *)livePhotoFileURL;

// record video
- (void)updateVideoFlashButtonStatus;
- (void)finishRecordingVideoWithMovieFileURL:(NSURL *)movieFileURL;


// scan qrcode
- (void)setRectOfInterestForScanningQRCode;
- (void)updateTorchButtonStatus;
- (void)finishScanQRCode;

@end
