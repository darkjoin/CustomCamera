//
//  CameraViewController.h
//  CustomCamera
//
//  Created by pro648 on 2018/7/20.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "CustomCameraDelegate.h"
#import "PhotoCaptureDelegate.h"
#import "VideoRecordDelegate.h"
#import "QRCodeScanDelegate.h"
#import "PreviewView.h"
#import "PlayerView.h"

typedef NS_ENUM(NSInteger, CaptureMode) {
    CaptureModeRewind = 0,
    CaptureModePhoto = 1,
    CaptureModeVideo = 2,
    CaptureModeScanQRCode = 3
};

typedef NS_ENUM(NSInteger, LivePhotoMode) {
    LivePhotoModeOn,
    LivePhotoModeOff
};

@interface CameraViewController : UIViewController

@property (nonatomic, weak) id<CustomCameraDelegate> delegate;
@property (nonatomic, strong) PhotoCaptureDelegate *photoCaptureDelegate;
@property (nonatomic, strong) VideoRecordDelegate *videoRecordDelegate;
@property (nonatomic, strong) QRCodeScanDelegate *qrcodeScanDelegate;

@property (nonatomic, assign) CGFloat beginGestureScale;
@property (nonatomic, assign) CGFloat effectiveScale;

@property (nonatomic, assign) CaptureMode captureMode;
@property (nonatomic, assign) LivePhotoMode livePhotoMode;
@property (nonatomic, assign) AVCaptureFlashMode flashMode;
@property (nonatomic, assign) AVCaptureTorchMode torchMode;

@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;

@property (nonatomic, strong) NSData *photoData;
@property (nonatomic, strong) NSURL *livePhotoFileURL;
@property (nonatomic, strong) NSURL *movieFileURL;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

- (instancetype)initWithPreview:(PreviewView *)preview;
- (void)playCapturedFile:(NSURL *)capturedFile onPlayerView:(PlayerView *)playerView;

- (void)changeCaptureMode:(CaptureMode)captureMode;
- (void)switchCamera;
- (void)toggleTorchWithTorchMode:(AVCaptureTorchMode)torchMode;
- (void)focusAndExposureTap:(UIGestureRecognizer *)gestureRecognizer;
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer;

- (void)capturePhoto;
- (void)recordVideo;
- (void)stopRecording;
- (void)scanQRCode;

- (void)savePhoto;
- (void)saveVideo;



@end
