//
//  CameraViewController.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/19.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController () <AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDevice *backCamera;

@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;

@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation CameraViewController

typedef NS_ENUM(NSInteger, CameraControllerError) {
    captureSessionAlreadyRunning,
    captureSessionIsMissing,
    inputsAreInvalid,
    invalidOperation,
    noCamerasAvailable,
    unknown,
};

- (void)prepare
{
    [self createCaptureSession];
    [self configureCaptureDevices];
    [self configureDeviceInputs];
    [self configurePhotoOutput];
}

- (void)displayPreviewOnView:(UIView *)view
{
    if (self.captureSession && self.captureSession.isRunning) {
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        self.previewLayer.frame = view.frame;
        
        [view.layer insertSublayer:self.previewLayer atIndex:0];
    }
    else {
        NSLog(@"%lu", captureSessionIsMissing);
    }
}

- (void)createCaptureSession
{
    self.captureSession = [[AVCaptureSession alloc] init];
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    }
}

- (void)configureCaptureDevices
{
    AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    NSArray *cameras = deviceDiscoverySession.devices;
    
    if (cameras) {
        for (AVCaptureDevice *camera in cameras) {
            if (camera.position == AVCaptureDevicePositionFront) {
                self.frontCamera = camera;
            }
            
            if (camera.position == AVCaptureDevicePositionBack) {
                self.backCamera = camera;
            }
            
            if ([self.backCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                NSError *error = nil;
                if ([self.backCamera lockForConfiguration:&error]) {
                    self.backCamera.focusMode = AVCaptureFocusModeAutoFocus;
                    [self.backCamera unlockForConfiguration];
                }
            }
        }
    }
    else {
        NSLog(@"%lu", noCamerasAvailable);
    }
}

- (void)configureDeviceInputs
{
    if (self.captureSession) {
        NSError *error;
        if (self.backCamera) {
            self.backCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backCamera error:&error];
            if (!self.backCameraInput) {
                NSLog(@"%lu", inputsAreInvalid);
            }
            else {
                if ([self.captureSession canAddInput:self.backCameraInput]) {
                    [self.captureSession addInput:self.backCameraInput];
                    self.currentCameraPosition = AVCaptureDevicePositionBack;
                }
            }
        }
        else if (self.frontCamera) {
            self.frontCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.frontCamera error:&error];
            if (!self.frontCameraInput) {
                NSLog(@"%lu", inputsAreInvalid);
            }
            else {
                if ([self.captureSession canAddInput:self.frontCameraInput]) {
                    [self.captureSession addInput:self.frontCameraInput];
                    self.currentCameraPosition = AVCaptureDevicePositionFront;
                }
            }
        }
        else {
            NSLog(@"%lu", noCamerasAvailable);
        }
    }
    else {
        NSLog(@"%lu", captureSessionIsMissing);
    }
}

- (void)configurePhotoOutput
{
    if (self.captureSession) {
        self.photoOutput = [[AVCapturePhotoOutput alloc] init];
        [self.photoOutput setPreparedPhotoSettingsArray:@[[AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey : AVVideoCodecTypeHEVC}]] completionHandler:nil];
        if ([self.captureSession canAddOutput:self.photoOutput]) {
            [self.captureSession addOutput:self.photoOutput];
        }
        
        [self.captureSession startRunning];
    }
    else {
        NSLog(@"%lu", captureSessionIsMissing);
    }
}

- (AVCaptureFlashMode)flashMode
{
    if (!_flashMode) {
        _flashMode = AVCaptureFlashModeOff;
    }
    
    return _flashMode;
}

- (void)switchCameras
{
    if (self.captureSession && self.captureSession.isRunning && self.currentCameraPosition) {
        [self.captureSession beginConfiguration];
        
        switch (self.currentCameraPosition) {
            case AVCaptureDevicePositionFront:
                [self switchToBackCamera];
                break;
            case AVCaptureDevicePositionBack:
                [self switchToFrontCamera];
                break;
            default:
                break;
        }
        
        [self.captureSession commitConfiguration];
    }
    else {
        NSLog(@"%lu", captureSessionIsMissing);
    }
}

- (void)switchToFrontCamera
{
    NSArray *inputs = self.captureSession.inputs;
    if ([inputs containsObject:self.backCameraInput]) {
        NSError *error;
        self.frontCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.frontCamera error:&error];
        [self.captureSession removeInput:self.backCameraInput];
        
        if ([self.captureSession canAddInput:self.frontCameraInput]) {
            [self.captureSession addInput:self.frontCameraInput];
            self.currentCameraPosition = AVCaptureDevicePositionFront;
        }
        else {
            NSLog(@"%lu", invalidOperation);
        }
    }
    else {
        NSLog(@"%lu", invalidOperation);
    }
}

- (void)switchToBackCamera
{
    NSArray *inputs = self.captureSession.inputs;
    if ([inputs containsObject:self.frontCameraInput]) {
        NSError *error;
        self.backCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backCamera error:&error];
        [self.captureSession removeInput:self.frontCameraInput];
        
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            [self.captureSession addInput:self.backCameraInput];
            self.currentCameraPosition = AVCaptureDevicePositionBack;
        }
        else {
            NSLog(@"%lu", invalidOperation);
        }
    }
    else {
        NSLog(@"%lu", invalidOperation);
    }
}

- (void)capturePhoto
{
    if (self.captureSession && self.captureSession.isRunning) {
        AVCapturePhotoSettings *photoSettings = [[AVCapturePhotoSettings alloc] init];
        photoSettings.flashMode = self.flashMode;
        
        [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
    }
    else {
        NSLog(@"%lu", captureSessionIsMissing);
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    if (photo) {
        NSData *imageData = photo.fileDataRepresentation;
        UIImage *capturedImage = [UIImage imageWithData:imageData];
        
        if (capturedImage) {
            // save image to album
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromImage:capturedImage];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                NSLog(@"success: %i, error: %@", success, [error localizedDescription]);
            }];
        }
        else {
            NSLog(@"There were no captured image.");
        }
    }
    else {
        NSLog(@"There were no such an AVCapturePhoto object.");
    }
}

@end
