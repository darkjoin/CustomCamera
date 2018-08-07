//
//  CameraViewController.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/20.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "CameraViewController.h"

static void *SessionRunningContext = &SessionRunningContext;
static void *itemStatusContext = &itemStatusContext;

typedef NS_ENUM(NSInteger, SetupResult) {
    SetupResultSuccess,
    SetupResultCameraNotAuthorized,
    SetupResultSessionConfigurationFailed
};

@interface AVCaptureDeviceDiscoverySession (Utilities)

- (NSInteger)uniqueDevicePositionCount;

@end

@implementation AVCaptureDeviceDiscoverySession (Utilities)

- (NSInteger)uniqueDevicePositionCount
{
    NSMutableArray<NSNumber *> *uniqueDevicePositions = [NSMutableArray array];
    
    for (AVCaptureDevice *device in self.devices) {
        if (![uniqueDevicePositions containsObject:@(device.position)]) {
            [uniqueDevicePositions addObject:@(device.position)];
        }
    }
    
    return uniqueDevicePositions.count;
}

@end

@interface CameraViewController () <CustomCameraDelegate>

@property (nonatomic, strong) PreviewView *previewView;

@property (nonatomic, assign) SetupResult setupResult;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;

@property (nonatomic, strong) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;

@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, PhotoCaptureDelegate *> *inProgressPhotoCaptureDelegates;
@property (nonatomic, assign) NSInteger inProgressLivePhotoCapturesCount;

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) dispatch_block_t cleanUpMovieFile;
@property (nonatomic, strong) dispatch_block_t cleanUpLivePhotoFile;

@end

@implementation CameraViewController

#pragma mark View Controller Life Cycle
- (instancetype)initWithPreview:(PreviewView *)preview
{
    self = [super init];
    if (self) {
        [self prepare];
        dispatch_async(self.sessionQueue, ^{
            [self configureCaptureSession];
        });
        [self setupPreview:preview];
        [self processSetupResult];
    }

    return self;
}

- (void)dealloc
{
    [self removeObservers];
}

#pragma mark Session Methods
- (void)prepare
{
    // Create the AVCaptureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // Create a device discovery session
    NSArray<AVCaptureDeviceType> *deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera];
    self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    
    // Create a session queue to communicate with the session and other session objects.
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    // Initialize
    self.setupResult = SetupResultSuccess;
    self.flashMode = AVCaptureFlashModeOff;
    self.torchMode = AVCaptureTorchModeOff;
    self.effectiveScale = 1.0;
    
    __weak typeof(self) weakSelf = self;
    self.cleanUpMovieFile = ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:weakSelf.movieFileURL.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:weakSelf.movieFileURL.path error:NULL];
        }
    };
    
    self.cleanUpLivePhotoFile = ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:weakSelf.livePhotoFileURL.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:weakSelf.livePhotoFileURL.path error:NULL];
        }
    };
    
    // Check video authorization status
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized: {
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (!granted) {
                    self.setupResult = SetupResultCameraNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
            }];
            break;
        }
        default: {
            self.setupResult = SetupResultCameraNotAuthorized;
            break;
        }
    }
}

- (void)configureCaptureSession
{
    if (self.setupResult != SetupResultSuccess) {
        return;
    }
    
    NSError *error = nil;
    
    [self.captureSession beginConfiguration];
    
    // 1 Configure capture session
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    // 2 Configure capture device
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    if (!videoDevice) {
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        if (!videoDevice) {
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        }
    }
    self.videoDevice = videoDevice;
    
    // 3 Configure device input
    // 3.1 add video input
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:&error];
    
    if (!videoDeviceInput) {
        NSLog(@"Could not create video device input: %@", error);
        self.setupResult = SetupResultSessionConfigurationFailed;
        [self.captureSession commitConfiguration];
        return;
    }
    
    if ([self.captureSession canAddInput:videoDeviceInput]) {
        [self.captureSession addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if (statusBarOrientation != UIInterfaceOrientationUnknown) {
                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
            }
            self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
        });
    }
    else {
        NSLog(@"Could not add video device input to the capture session");
        self.setupResult = SetupResultSessionConfigurationFailed;
        [self.captureSession commitConfiguration];
        return;
    }

    // 3.2 add audio input
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!audioDeviceInput) {
        NSLog(@"Could not create audio device input: %@", error);
    }
    
    if ([self.captureSession canAddInput:audioDeviceInput]) {
        [self.captureSession addInput:audioDeviceInput];
    }
    else {
        NSLog(@"Could not add audio device input to the session.");
    }
    
    // 4 Configure output
    // 4.1 Add photo output
    AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.captureSession canAddOutput:photoOutput]) {
        [self.captureSession addOutput:photoOutput];
        self.photoOutput = photoOutput;
        
        self.photoOutput.highResolutionCaptureEnabled = YES;
        self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
        self.livePhotoMode = self.photoOutput.livePhotoCaptureSupported ? LivePhotoModeOn : LivePhotoModeOff;
        
        self.inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionary];
        self.inProgressLivePhotoCapturesCount = 0;
    }
    else {
        NSLog(@"Could not add photo output to the session");
        self.setupResult = SetupResultSessionConfigurationFailed;
        [self.captureSession commitConfiguration];
        return;
    }
    
    [self.captureSession commitConfiguration];
}

- (void)setupPreview:(PreviewView *)preview
{
    preview.session = self.captureSession;
    preview.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewView = preview;
}

- (void)processSetupResult
{
    dispatch_async(self.sessionQueue, ^{
        switch (self.setupResult) {
            case SetupResultSuccess: {
                [self addObservers];
                [self.captureSession startRunning];
                self.sessionRunning = self.captureSession.isRunning;
                break;
            }
            case SetupResultCameraNotAuthorized:{
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"CustomCamera doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CustomCamera" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case SetupResultSessionConfigurationFailed: {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CustomCamera" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            default:
                break;
        }
    });
}

#pragma mark Actions
- (void)changeCaptureMode:(CaptureMode)captureMode
{
    if ([self.delegate respondsToSelector:@selector(prepareUIForChangingCaptureMode:)]) {
        [self.delegate prepareUIForChangingCaptureMode:captureMode];
    }

    if (captureMode == CaptureModePhoto) {
        dispatch_async(self.sessionQueue, ^{
            [self.captureSession beginConfiguration];
            
            [self.captureSession removeOutput:self.movieFileOutput];
            [self.captureSession removeOutput:self.metadataOutput];
            
            self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
            
            self.movieFileOutput = nil;
            
            if (self.photoOutput.livePhotoCaptureSupported) {
                self.photoOutput.livePhotoCaptureEnabled = YES;
                self.livePhotoMode = LivePhotoModeOn;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(updateLivePhotoButtonStatus)]) {
                        [self.delegate updateLivePhotoButtonStatus];
                    }
                });
            }

            [self.captureSession commitConfiguration];
        });
    }
    else if (captureMode == CaptureModeVideo | captureMode == CaptureModeRewind) {
        self.torchMode = AVCaptureTorchModeOff;
        
        dispatch_async(self.sessionQueue, ^{
            AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            
            if ([self.captureSession canAddOutput:movieFileOutput]) {
                [self.captureSession beginConfiguration];
                
                [self.captureSession removeOutput:self.metadataOutput];
                [self.captureSession addOutput:movieFileOutput];
                
                self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
                
                AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
                if (connection.isVideoStabilizationSupported) {
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
                
                [self.captureSession commitConfiguration];
                
                self.movieFileOutput = movieFileOutput;
            }
        });
        
        [self toggleTorchWithTorchMode:self.torchMode];
        
        if ([self.delegate respondsToSelector:@selector(updateVideoFlashButtonStatus)]) {
            [self.delegate updateVideoFlashButtonStatus];
        }
    }
    else if (captureMode == CaptureModeScanQRCode) {
        self.torchMode = AVCaptureTorchModeOff;
        
        dispatch_async(self.sessionQueue, ^{
            self.qrcodeScanDelegate = [[QRCodeScanDelegate alloc] init];
            self.qrcodeScanDelegate.delegate = self;
            AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
            
            if ([self.captureSession canAddOutput:metadataOutput]) {
                [self.captureSession beginConfiguration];

                [self.captureSession removeOutput:self.movieFileOutput];
                [self.captureSession addOutput:metadataOutput];
                
                [metadataOutput setMetadataObjectsDelegate:self.qrcodeScanDelegate queue:self.sessionQueue];
                [metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
                
                [self toggleTorchWithTorchMode:self.torchMode];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(updateTorchButtonStatus)]) {
                        [self.delegate updateTorchButtonStatus];
                    }
                });
                
                [self.captureSession commitConfiguration];
                
                self.metadataOutput = metadataOutput;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(setRectOfInterestForScanningQRCode)]) {
                        [self.delegate setRectOfInterestForScanningQRCode];
                    }
                });
                
                [self scanQRCode];
            }
        });
    }
}

- (void)switchCamera
{
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        AVCaptureDevicePosition preferredPosition;
        AVCaptureDeviceType preferredDeviceType;
        
        switch (currentPosition) {
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInDualCamera;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
                break;
            default:
                break;
        }
        
        NSArray<AVCaptureDevice *> *devices = self.videoDeviceDiscoverySession.devices;
        AVCaptureDevice *newVideoDevice = nil;
        
        // First, look for a device with both the preferred position and device type.
        for (AVCaptureDevice *device in devices) {
            if (device.position == preferredPosition && device.deviceType == preferredDeviceType) {
                newVideoDevice = device;
                break;
            }
        }
        
        // Otherwise, look for a device with only the preferred position.
        if (!newVideoDevice) {
            for (AVCaptureDevice *device in devices) {
                if (device.position == preferredPosition) {
                    newVideoDevice = device;
                    break;
                }
            }
        }
        
        if (newVideoDevice) {
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];
            
            [self.captureSession beginConfiguration];
            
            [self.captureSession removeInput:self.videoDeviceInput];
            
            if ([self.captureSession canAddInput:videoDeviceInput]) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];
                
                [self.captureSession addInput:videoDeviceInput];
                self.videoDeviceInput = videoDeviceInput;
            }
            else {
                [self.captureSession addInput:self.videoDeviceInput];
            }
            
            AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if (movieFileOutputConnection.isVideoStabilizationSupported) {
                movieFileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            
            self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
            
            [self.captureSession commitConfiguration];
        }
    });
}

- (void)toggleTorchWithTorchMode:(AVCaptureTorchMode)torchMode
{
    if ([self.videoDevice hasTorch]) {
        NSError *error;
        if ([self.videoDevice isTorchModeSupported:self.torchMode]) {
            [self.videoDevice lockForConfiguration:&error];
            self.videoDevice.torchMode = self.torchMode;
            [self.videoDevice unlockForConfiguration];
        }
    }
}

- (void)focusAndExposureTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [self.previewView.videoPreviewLayer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for (i = 0; i < numTouches; ++i) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.previewView];
        CGPoint convertedLocation = [self.previewView.videoPreviewLayer convertPoint:location fromLayer:self.previewView.videoPreviewLayer.superlayer];
        if (![self.previewView.videoPreviewLayer containsPoint:convertedLocation]) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if (allTouchesAreOnThePreviewLayer) {
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0) {
            self.effectiveScale = 1.0;
        }
        CGFloat maxScaleAndCropFactor = [[self.photoOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        if (self.effectiveScale > maxScaleAndCropFactor) {
            self.effectiveScale = maxScaleAndCropFactor;
        }
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewView.videoPreviewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
    }
}

#pragma mark Capture Methods
- (void)capturePhoto
{
    AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.previewView.videoPreviewLayer.connection.videoOrientation;
    
    dispatch_async(self.sessionQueue, ^{
        // Update the photo output's connection to match the video orientation of the video preview layer.
        AVCaptureConnection *photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
        photoOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
        photoOutputConnection.videoScaleAndCropFactor = self.effectiveScale;
        
        AVCapturePhotoSettings *photoSettings;
        // Capture HEIF photo when supported
        if ([self.photoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
            photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey : AVVideoCodecTypeHEVC}];
        }
        else {
            photoSettings = [AVCapturePhotoSettings photoSettings];
        }
        
        if (self.videoDeviceInput.device.isFlashAvailable) {
            photoSettings.flashMode = self.flashMode;
        }
        
        photoSettings.highResolutionPhotoEnabled = YES;
        
        if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0) {
            photoSettings.previewPhotoFormat = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject};
        }
        
        if (self.livePhotoMode == LivePhotoModeOn && self.photoOutput.livePhotoCaptureSupported) {
            // Live photo capture is not supported in video mode.
            NSString *livePhotoMovieFileName = [NSUUID UUID].UUIDString;
            NSString *livePhotoMovieFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[livePhotoMovieFileName stringByAppendingPathExtension:@"mov"]];
            photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:livePhotoMovieFilePath];
        }
        
        // Use a separate object for the photo capture delegate to isolate each capture life cycle.
        self.photoCaptureDelegate = [[PhotoCaptureDelegate alloc] initWithRequestedPhotoSettings:photoSettings willCapturePhotoAnimation:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.previewView.videoPreviewLayer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewView.videoPreviewLayer.opacity = 1.0;
                }];
            });
        } livePhotoCaptureHandler:^(BOOL capturing) {
            dispatch_async(self.sessionQueue, ^{
                if (capturing) {
                    self.inProgressLivePhotoCapturesCount++;
                }
                else {
                    self.inProgressLivePhotoCapturesCount--;
                }
            });
        } completionHandler:^(PhotoCaptureDelegate *photoCaptureDelegate) {
            // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
            dispatch_async(self.sessionQueue, ^{
                self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = nil;
            });
        }];
        
        self.photoCaptureDelegate.delegate = self;
        
        // The photo output keeps a weak reference to the photo capture delegate so we store it in an array to maintain a strong reference to this object until the capture is completed.
    self.inProgressPhotoCaptureDelegates[@(self.photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = self.photoCaptureDelegate;
        
        [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self.photoCaptureDelegate];
    });
}

- (void)recordVideo
{
    AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.previewView.videoPreviewLayer.connection.videoOrientation;
    
    dispatch_async(self.sessionQueue, ^{
        AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        movieFileOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
        movieFileOutputConnection.videoScaleAndCropFactor = self.effectiveScale;
        
        // Use HEVC codec if supported
        if ([self.movieFileOutput.availableVideoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
            [self.movieFileOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecTypeHEVC} forConnection:movieFileOutputConnection];
        }
        
        // Start recording to a temporary file.
        NSString *outputFileName = [NSUUID UUID].UUIDString;
        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
        
        self.videoRecordDelegate = [[VideoRecordDelegate alloc] init];
        self.videoRecordDelegate.delegate = self;
        
        [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self.videoRecordDelegate];
    });
}

- (void)stopRecording
{
    [self.movieFileOutput stopRecording];
}

- (void)scanQRCode
{
    [self loadSound];
    [self.captureSession startRunning];
}

#pragma mark Save Methods
- (void)savePhoto
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                options.uniformTypeIdentifier = self.photoCaptureDelegate.requestedPhotoSettings.processedFileType;
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:self.photoData options:options];
                
                if (self.livePhotoFileURL) {
                    PHAssetResourceCreationOptions *livePhotoCompanionMovieResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
                    livePhotoCompanionMovieResourceOptions.shouldMoveFile = YES;
                    [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:self.livePhotoFileURL options:livePhotoCompanionMovieResourceOptions];
                }
                
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    NSLog(@"Error occurred while saving photo to photo library: %@", error);
                }
                self.cleanUpLivePhotoFile();
            }];
        }
        else {
            NSLog(@"Not authorized to save photo");
            self.cleanUpLivePhotoFile();
        }
    }];
}

- (void)saveVideo
{
    // Check authorization status.
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            // Save the movie file to the photo library and clean up.
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                options.shouldMoveFile = YES;
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:self.movieFileURL options:options];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    NSLog(@"Could not save movie to photo library: %@", error);
                }
                self.cleanUpMovieFile();
            }];
        }
        else {
            self.cleanUpMovieFile();
        }
    }];
}

#pragma mark CustomCameraDelegate
- (void)finishCapturePhotoWithPhotoData:(NSData *)photoData andWithLivePhotoFileURL:(NSURL *)livePhotoFileURL
{
    self.photoData = photoData;
    self.livePhotoFileURL = livePhotoFileURL;
    
    if ([self.delegate respondsToSelector:@selector(prepareUIForSaving)]) {
        [self.delegate prepareUIForSaving];
    }
}

- (void)finishRecordingVideoWithMovieFileURL:(NSURL *)movieFileURL
{
    if (self.captureMode == CaptureModeVideo) {
        self.movieFileURL = movieFileURL;
    }
    else if (self.captureMode == CaptureModeRewind) {
        self.movieFileURL = [self reverseMovieFile:movieFileURL];
    }
    
    if ([self.delegate respondsToSelector:@selector(prepareUIForSaving)]) {
        [self.delegate prepareUIForSaving];
    }
}

- (void)finishScanQRCode
{
    [self.captureSession stopRunning];
    
    if (self.audioPlayer) {
        [self.audioPlayer play];
    }
}

#pragma mark KVO and Notifications
- (void)addObservers
{
    [self.captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.captureSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.captureSession];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.captureSession removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    [self.playerItem removeObserver:self forKeyPath:@"status" context:itemStatusContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == SessionRunningContext) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        self.sessionRunning = isSessionRunning;
    }
    else if (context == itemStatusContext) {
        if ([keyPath isEqualToString:@"status"]) {
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                [self.player play];
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(0.5, 0.5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode]) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog(@"Could not lock device for configuration: %@", error);
        }
    });
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog(@"Capture session runtime error: %@", error);
    
    // Automatically try to restart the session running if media services were reset and the last start running succeeded.
    if (error.code == AVErrorMediaServicesWereReset) {
        dispatch_async(self.sessionQueue, ^{
            if (self.isSessionRunning) {
                [self.captureSession startRunning];
                self.sessionRunning = self.captureSession.isRunning;
            }
        });
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    NSLog(@"Capture session was interrupted with reason %ld", (long)reason);
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog(@"Capture session interruption ended.");
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

#pragma mark Help Methods
- (void)loadSound
{
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"mp3"];
    NSURL *soundURL = [NSURL URLWithString:soundFilePath];
    NSError *error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
    
    if (error) {
        NSLog(@"Could not play sound file: %@", [error localizedDescription]);
    }
    else {
        [self.audioPlayer prepareToPlay];
    }
}

- (void)playCapturedFile:(NSURL *)capturedFileURL onPlayerView:(PlayerView *)playerView
{
    self.playerItem = [AVPlayerItem playerItemWithURL:capturedFileURL];
    
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&itemStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    playerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerView.player = self.player;
}

- (NSURL *)reverseMovieFile:(NSURL *)movieFileURL
{
    // initialize the reader
    NSError *error;
    AVAsset *asset = [AVAsset assetWithURL:movieFileURL];
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    NSDictionary *readerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_422YpCbCr8], (id)kCVPixelBufferPixelFormatTypeKey, [NSDictionary dictionary], (id)kCVPixelBufferIOSurfacePropertiesKey, nil];
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:readerOutputSettings];
    if ([reader canAddOutput:readerOutput]) {
        [reader addOutput:readerOutput];
    }
    
    // Start the asset reader up.
    [reader startReading];
    
    BOOL done = NO;
    NSMutableArray *samples = [[NSMutableArray alloc] init];
    
    while (!done) {
        // Copy the next sample buffer from the reader output.
        CMSampleBufferRef sampleBuffer = [readerOutput copyNextSampleBuffer];
        if (sampleBuffer) {
            [samples addObject:(__bridge id)sampleBuffer];
            CFRelease(sampleBuffer);
            sampleBuffer = NULL;
        }
        else {
            // Find out why the asset reader output couldn't copy another sample buffer.
            if (reader.status == AVAssetReaderStatusFailed) {
                NSError *failureError = reader.error;
                // Handle the error here.
                NSLog(@"Failed to reading the asset: %@", failureError.description);
            }
            else {
                // The asset reader output has read all of its samples.
                done = YES;
            }
        }
    }
    
    // initialize the writer
    NSString *outputFileName = [NSUUID UUID].UUIDString;
    NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
    NSURL *reversedURL = [NSURL fileURLWithPath:outputFilePath];
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:reversedURL fileType:AVFileTypeMPEG4 error:&error];
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:@(videoTrack.estimatedDataRate), AVVideoAverageBitRateKey, nil];
    NSDictionary *writerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecTypeHEVC, AVVideoCodecKey,[NSNumber numberWithInt:videoTrack.naturalSize.width], AVVideoWidthKey, [NSNumber numberWithInt:videoTrack.naturalSize.height], AVVideoHeightKey, videoCompressionProps, AVVideoCompressionPropertiesKey, nil];
    AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:writerOutputSettings sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
    [writerInput setExpectsMediaDataInRealTime:NO];
    writerInput.transform = videoTrack.preferredTransform;
    
    // initialize an input adaptor so that we can append picelBuffer
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    [writer addInput:writerInput];
    
    [writer startWriting];
    [writer startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[0])];
    //    [writer startSessionAtSourceTime:kCMTimeZero];
    
    // append the frames to the output
    // Notice we append the frames from the tail end, using the timing of the frames from the front.
    for (int i = 0; i < samples.count; ++i) {
        // get the presentation time for the frame
        CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[i]);
        
        // take the image/pixel buffer from tail end of the array
        CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples[samples.count - i - 1]);
        while (!writerInput.readyForMoreMediaData) {
            [NSThread sleepForTimeInterval:0.1];
        }
        
        [pixelBufferAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:presentationTime];
    }
    
    [writer finishWriting];
    
    return reversedURL;
}

@end
