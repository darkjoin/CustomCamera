//
//  MainViewController.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/19.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "MainViewController.h"
#import "CameraViewController.h"

#import "PreviewView.h"
#import "PlayerView.h"
#import "ScanView.h"
#import "FocusView.h"
#import "MarkView.h"
#import "PhotoButton.h"
#import "VideoButton.h"
#import "RewindButton.h"
#import "StopButton.h"
#import "SaveButton.h"

@interface MainViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, CustomCameraDelegate>

@property (nonatomic, strong) CameraViewController *cameraViewController;

@property (nonatomic, strong) PreviewView *previewView;
@property (nonatomic, strong) ScanView *scanView;
@property (nonatomic, strong) FocusView *focusView;
@property (nonatomic, strong) MarkView *markView;
@property (nonatomic, strong) UIView *containerView;    // container for picker view
@property (nonatomic, strong) UIPickerView *pickerView;

@property (nonatomic, strong) UIView *saveView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *livePhotoLabel;
@property (nonatomic, strong) PlayerView *playerView;

@property (nonatomic, strong) CALayer *maskLayer;

@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, strong) PhotoButton *photoButton;
@property (nonatomic, strong) VideoButton *videoButton;
@property (nonatomic, strong) StopButton *stopButton;
@property (nonatomic, strong) RewindButton *rewindButton;
@property (nonatomic, strong) UIButton *scanQRCodeButton;
@property (nonatomic, strong) SaveButton *saveButton;

@property (nonatomic, strong) UIButton *livePhotoButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *videoFlashButton;
@property (nonatomic, strong) UIButton *torchButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *albumButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *shareButton;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeRightGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeLeftGestureRecognizer;

@property (nonatomic, strong) NSArray *itemsArray;
@property (nonatomic, strong) NSMutableArray *captureButtonsArray;

@end

@implementation MainViewController

#pragma mark View Controller Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cameraViewController = [[CameraViewController alloc] initWithPreview:self.previewView];
    self.cameraViewController.delegate = self;
    
    [self addObservers];
    [self setupUI];
    [self addGestureRecognizers];
}

- (BOOL)shouldAutorotate
{
    return !((self.cameraViewController.movieFileOutput.isRecording) || (self.cameraViewController.captureMode == CaptureModeScanQRCode));
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;

    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
        self.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

- (void)dealloc
{
    [self removeObservers];
}

#pragma mark UI Methods
- (void)setupUI
{
    [self setupPreviewView];
    [self setupScanView];
    [self setupFocusView];
    [self setupMarkView];
    [self setupContainerView];
    [self setupPickerView];
    [self setupCaptureButton];
    [self setupLivePhotoButton];
    [self setupFlashButton];
    [self setupVideoFlashButton];
    [self setupCameraButton];
    [self setupTorchButton];
    [self setupAlbumButton];
}

- (void)addGestureRecognizers
{
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAndExposureTap:)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    self.pinchGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.pinchGestureRecognizer];
    
    self.swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToRightWithGestureRecognizer:)];
    self.swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.swipeRightGestureRecognizer];
    
    self.swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToLeftWithGestureRecognizer:)];
    self.swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.swipeLeftGestureRecognizer];
}

#pragma mark Toggle Actions
- (void)switchCamera:(UIButton *)cameraButton
{
    [self.cameraViewController switchCamera];
}

- (void)toggleLivePhotoMode:(UIButton *)livePhotoButton
{
    switch (self.cameraViewController.livePhotoMode) {
        case LivePhotoModeOn:
            self.cameraViewController.livePhotoMode = LivePhotoModeOff;
            [self.livePhotoButton setImage:[UIImage imageNamed:@"livePhotoOff"] forState:UIControlStateNormal];
            break;
        case LivePhotoModeOff:
            self.cameraViewController.livePhotoMode = LivePhotoModeOn;
            [self.livePhotoButton setImage:[UIImage imageNamed:@"livePhotoOn"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)toggleFlashMode:(UIButton *)flashButton
{
    switch (self.cameraViewController.flashMode) {
        case AVCaptureFlashModeOn:
            self.cameraViewController.flashMode = AVCaptureFlashModeOff;
            [self.flashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
            break;
        case AVCaptureFlashModeOff:
            self.cameraViewController.flashMode = AVCaptureFlashModeAuto;
            [self.flashButton setImage:[UIImage imageNamed:@"flashAuto"] forState:UIControlStateNormal];
            break;
        case AVCaptureFlashModeAuto:
            self.cameraViewController.flashMode = AVCaptureFlashModeOn;
            [self.flashButton setImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)toggleVideoFlashMode:(UIButton *)videoFlashButton
{
    switch (self.cameraViewController.torchMode) {
        case AVCaptureTorchModeOn:
            self.cameraViewController.torchMode = AVCaptureTorchModeOff;
            [self.videoFlashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
            break;
        case AVCaptureTorchModeOff:
            self.cameraViewController.torchMode = AVCaptureTorchModeAuto;
            [self.videoFlashButton setImage:[UIImage imageNamed:@"flashAuto"] forState:UIControlStateNormal];
            break;
        case AVCaptureTorchModeAuto:
            self.cameraViewController.torchMode = AVCaptureTorchModeOn;
            [self.videoFlashButton setImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
    [self.cameraViewController toggleTorchWithTorchMode:self.cameraViewController.torchMode];
}

- (void)toggleTorchMode:(UIButton *)torchButton
{
    switch (self.cameraViewController.torchMode) {
        case AVCaptureTorchModeOn:
            self.cameraViewController.torchMode = AVCaptureTorchModeOff;
            [self.torchButton setImage:[UIImage imageNamed:@"torchOff"] forState:UIControlStateNormal];
            break;
        case AVCaptureTorchModeOff:
            self.cameraViewController.torchMode = AVCaptureTorchModeOn;
            [self.torchButton setImage:[UIImage imageNamed:@"torchOn"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
    [self.cameraViewController toggleTorchWithTorchMode:self.cameraViewController.torchMode];
}

- (void)readingFromAlbum:(UIButton *)albumButton
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES;
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark Gesture Actions
- (void)focusAndExposureTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.cameraViewController focusAndExposureTap:tapGestureRecognizer];
    
    CGPoint point = [tapGestureRecognizer locationInView:tapGestureRecognizer.view];
    self.focusView.center = point;
    self.focusView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            self.focusView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.focusView.hidden = YES;
        }];
    }];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    [self.cameraViewController handlePinchGesture:pinchGestureRecognizer];
}

- (void)swipeToRightWithGestureRecognizer:(UISwipeGestureRecognizer *)swipeGestureRecognizer
{
    NSUInteger currentIndex, nextIndex;
    currentIndex = [self.pickerView selectedRowInComponent:0];
    if (currentIndex <= 0) {
        return;
    }
    else {
        nextIndex = currentIndex - 1;
        
        [self.pickerView selectRow:nextIndex inComponent:0 animated:YES];
        [self pickerView:self.pickerView didSelectRow:nextIndex inComponent:0];
    }
}

- (void)swipeToLeftWithGestureRecognizer:(UISwipeGestureRecognizer *)swipeGestureRecognizer
{
    NSUInteger currentIndex, nextIndex;
    currentIndex = [self.pickerView selectedRowInComponent:0];
    if (currentIndex >= self.itemsArray.count - 1) {
        return;
    }
    else {
        nextIndex = currentIndex + 1;
        
        [self.pickerView selectRow:nextIndex inComponent:0 animated:YES];
        [self pickerView:self.pickerView didSelectRow:nextIndex inComponent:0];
    }
}

#pragma mark Capture Actions
- (void)capturePhoto:(UIButton *)photoButton
{
    [self.cameraViewController capturePhoto];
}

- (void)recordVideo:(UIButton *)videoButton
{
    [self.cameraViewController recordVideo];
}

- (void)stopRecording:(UIButton *)stopButton
{
    [self.cameraViewController stopRecording];
}

- (void)scanQRCode
{
    self.scanView.timer.fireDate = [NSDate distantPast];
    [self.cameraViewController scanQRCode];
}

#pragma mark Save Actions
- (void)save:(UIButton *)saveButton
{
    [self.cameraViewController.player pause];
    
    if (self.cameraViewController.captureMode == CaptureModePhoto) {
        [self.cameraViewController savePhoto];
    }
    else if ((self.cameraViewController.captureMode == CaptureModeVideo) || (self.cameraViewController.captureMode == CaptureModeRewind)) {
        [self.cameraViewController saveVideo];
    }
    
    [self.imageView removeFromSuperview];
    [self.playerView removeFromSuperview];
    [self.saveView removeFromSuperview];
    
    [self enableGestureRecognizers];
}

- (void)cancel:(UIButton *)cancelButton
{
    [self.cameraViewController.player pause];
    
    [self.imageView removeFromSuperview];
    [self.playerView removeFromSuperview];
    [self.saveView removeFromSuperview];
    
    [self enableGestureRecognizers];
}

- (void)share:(UIButton *)shareButton
{
    UIActivityViewController *activityViewController;

    if (self.cameraViewController.captureMode == CaptureModePhoto) {
        if (self.cameraViewController.photoData) {
            activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.cameraViewController.photoData] applicationActivities:nil];
        }
    }
    else if ((self.cameraViewController.captureMode == CaptureModeVideo) || (self.cameraViewController.captureMode == CaptureModeRewind)) {
        if (self.cameraViewController.movieFileURL) {
            activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.cameraViewController.movieFileURL] applicationActivities:nil];
        }
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark UIPickerView Data Source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.itemsArray.count;
}

#pragma mark UIPickerView Delegate
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    [self hidesSeparatorLineOfPickerView:pickerView];
    
    CGAffineTransform labelRotation = CGAffineTransformMakeRotation(M_PI/2);
    
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        label.text = self.itemsArray[row];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.transform = labelRotation;
    }
    
    return label;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 60;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
    //    [self.cameraViewController changeCaptureMode:row];
    //    self.cameraViewController.captureMode = row;
    //
    //    [self resetCaptureButtonWithButton:self.captureButtonsArray[row]];
    
    self.previewView.videoPreviewLayer.opacity = 0.3;
    
    [UIView animateWithDuration:1.0 animations:^{
        [self.cameraViewController changeCaptureMode:row];
        [self resetCaptureButtonWithButton:self.captureButtonsArray[row]];
        self.previewView.videoPreviewLayer.opacity = 1.0;
    } completion:^(BOOL finished) {
        self.cameraViewController.captureMode = row;
    }];
}

#pragma mark UIImagePickerController Delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    CIImage *ciImage = [[CIImage alloc] initWithImage:selectedImage];
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyLow}];
    NSArray *features = [detector featuresInImage:ciImage];
    
    if (features.count > 0) {
        CIQRCodeFeature *feature = features.firstObject;
        NSString *message = feature.messageString;
        
        // play sound
        if (self.cameraViewController.audioPlayer) {
            [self.cameraViewController.audioPlayer play];
        }
        
        // stop timer and display message
        [self finishScanningQRCodeWithMessage:message];
    }
}

#pragma mark UIGestureRecognizer Delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        self.cameraViewController.beginGestureScale = self.cameraViewController.effectiveScale;
    }
    
    return YES;
}

#pragma mark CustomCameraDelegate
- (void)prepareUIForChangingCaptureMode:(NSUInteger)captureMode
{
    self.livePhotoButton.hidden = !(captureMode == CaptureModePhoto);
    self.flashButton.hidden = !(captureMode == CaptureModePhoto);
    self.videoFlashButton.hidden = !(captureMode == CaptureModeVideo || captureMode == CaptureModeRewind);
    self.cameraButton.hidden = (captureMode == CaptureModeScanQRCode);
    self.albumButton.hidden = !(captureMode == CaptureModeScanQRCode);
    self.scanView.hidden = !(captureMode == CaptureModeScanQRCode);
    
    captureMode == CaptureModeScanQRCode ? [self setupMaskLayer] : [self.maskLayer removeFromSuperlayer];
}

- (void)prepareUIForSaving
{
    [self disableGestureRecognizers];
    
    [self setupSaveView];
    
    if (self.cameraViewController.captureMode == CaptureModePhoto) {
        if (self.cameraViewController.photoData) {
            [self setupImageView];
            self.imageView.image = [UIImage imageWithData:self.cameraViewController.photoData];
            
            if (self.cameraViewController.livePhotoFileURL) {
                [self setupLivePhotoLabel];
            }
            else {
                [self.livePhotoLabel removeFromSuperview];
            }
        }
    }
    else if ((self.cameraViewController.captureMode == CaptureModeVideo) || (self.cameraViewController.captureMode == CaptureModeRewind)) {
        if (self.cameraViewController.movieFileURL) {
            [self setupPlayerView];
            [self.cameraViewController playCapturedFile:self.cameraViewController.movieFileURL onPlayerView:self.playerView];
        }
    }
}

- (void)updateLivePhotoButtonStatus
{
    [self setImageForLivePhotoButton];
}

- (void)updateVideoFlashButtonStatus
{
    [self setImageForVideoFlashButton];
}

- (void)updateTorchButtonStatus
{
    [self setImageForTorchButton];
}

- (void)setRectOfInterestForScanningQRCode
{
    // set the scanning area
    [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        self.cameraViewController.metadataOutput.rectOfInterest = [self.previewView.videoPreviewLayer metadataOutputRectOfInterestForRect:self.scanView.frame];
    }];
}

#pragma mark Notifications
- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStartRecording:) name:@"kDidStartRecordingNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishRecording:) name:@"kDidFinishRecordingNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didOutputMetadataObjects:) name:@"kDidOutputMetadataObjects" object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kDidStartRecordingNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kDidFinishRecordingNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kDidOutputMetadataObjects" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
}

- (void)didStartRecording:(NSNotification *)notification
{
    [self resetCaptureButtonWithButton:self.stopButton];
    
    self.videoFlashButton.hidden = YES;
    self.cameraButton.hidden = YES;
    self.pickerView.hidden = YES;
    self.markView.hidden = YES;
}

- (void)didFinishRecording:(NSNotification *)notification
{
    if (self.cameraViewController.captureMode == CaptureModeVideo) {
        [self resetCaptureButtonWithButton:self.videoButton];
    }
    else if (self.cameraViewController.captureMode == CaptureModeRewind) {
        [self resetCaptureButtonWithButton:self.rewindButton];
    }
    
    self.videoFlashButton.hidden = NO;
    self.cameraButton.hidden = NO;
    self.pickerView.hidden = NO;
    self.markView.hidden = NO;
}

- (void)didOutputMetadataObjects:(NSNotification *)notification
{
    // display qrcode message
    NSDictionary *dict = [notification userInfo];
    NSString *message = [dict objectForKey:@"QRCodeMessage"];
    
    [self finishScanningQRCodeWithMessage:message];
}

#pragma mark Help Methods
- (void)resetCaptureButtonWithButton:(UIButton *)button
{
    [self.captureButton removeFromSuperview];
    self.captureButton = button;
    [self setupCaptureButton];
}

- (void)hidesSeparatorLineOfPickerView:(UIPickerView *)pickerView
{
    for (UIView *separatorLineView in pickerView.subviews) {
        separatorLineView.hidden = separatorLineView.bounds.size.height < 1;
    }
}

- (void)finishScanningQRCodeWithMessage:(NSString *)message
{
    // stop timer
    self.scanView.timer.fireDate = [NSDate distantFuture];
    
    // display scan message
    [self displayQRCodeMessage:message];
}

- (void)displayQRCodeMessage:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"QRCode Message" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self scanQRCode];
        });
        
    }];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)enableGestureRecognizers
{
    self.tapGestureRecognizer.enabled = YES;
    self.pinchGestureRecognizer.enabled = YES;
    self.swipeRightGestureRecognizer.enabled = YES;
    self.swipeLeftGestureRecognizer.enabled = YES;
}

- (void)disableGestureRecognizers
{
    self.tapGestureRecognizer.enabled = NO;
    self.pinchGestureRecognizer.enabled = NO;
    self.swipeRightGestureRecognizer.enabled = NO;
    self.swipeLeftGestureRecognizer.enabled = NO;
}

- (void)setImageForLivePhotoButton
{
    switch (self.cameraViewController.livePhotoMode) {
        case LivePhotoModeOn:
            [self.livePhotoButton setImage:[UIImage imageNamed:@"livePhotoOn"] forState:UIControlStateNormal];
            break;
        case LivePhotoModeOff:
            [self.livePhotoButton setImage:[UIImage imageNamed:@"livePhotoOff"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)setImageForVideoFlashButton
{
    switch (self.cameraViewController.torchMode) {
        case AVCaptureTorchModeAuto:
            [self.videoFlashButton setImage:[UIImage imageNamed:@"flashAuto"] forState:UIControlStateNormal];
        case AVCaptureTorchModeOn:
            [self.videoFlashButton setImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
            break;
        case AVCaptureTorchModeOff:
            [self.videoFlashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)setImageForTorchButton
{
    switch (self.cameraViewController.torchMode) {
        case AVCaptureTorchModeOn:
            [self.torchButton setImage:[UIImage imageNamed:@"torchOn"] forState:UIControlStateNormal];
            break;
        case AVCaptureTorchModeOff:
            [self.torchButton setImage:[UIImage imageNamed:@"torchOff"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}
#pragma mark Setup Views
- (void)setupPreviewView
{
    [self.view addSubview:self.previewView];
    [self addPreviewViewConstraints];
}

- (void)setupScanView
{
    [self.view addSubview:self.scanView];
    [self addScanViewConstraints];
}

- (void)setupFocusView
{
    [self.view addSubview:self.focusView];
}

- (void)setupMarkView
{
    [self.view addSubview:self.markView];
    [self addMarkViewConstraints];
}

- (void)setupContainerView
{
    [self.view addSubview:self.containerView];
    [self addContainerViewConstraints];
}

- (void)setupPickerView
{
    CGAffineTransform rotation = CGAffineTransformMakeRotation(-M_PI/2);
    self.pickerView.transform = rotation;
    self.pickerView.center = CGPointMake(CGRectGetWidth(self.containerView.bounds)/2, CGRectGetHeight(self.containerView.bounds)/2);
    
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    [self.pickerView selectRow:1 inComponent:0 animated:NO];
    [self pickerView:self.pickerView didSelectRow:1 inComponent:0];
    
    [self.containerView addSubview:self.pickerView];
}

- (void)setupSaveView
{
    [self.view addSubview:self.saveView];
    [self addSaveViewConstraints];
    
    [self setupCancelButton];
    [self setupShareButton];
    [self setupSaveButton];
}

- (void)setupImageView
{
    [self.saveView insertSubview:self.imageView atIndex:0];
    [self addImageViewConstraints];
}

- (void)setupLivePhotoLabel
{
    [self.imageView addSubview:self.livePhotoLabel];
    [self addLivePhotoLabelConstraints];
}

- (void)setupPlayerView
{
    self.playerView.player = self.cameraViewController.player;
    [self.saveView insertSubview:self.playerView atIndex:0];
    [self addPlayerViewConstraints];
}

- (void)setupMaskLayer
{
    self.maskLayer = [[CALayer alloc] init];
    self.maskLayer.frame = self.previewView.bounds;
    self.maskLayer.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.5].CGColor;
    [self.previewView.videoPreviewLayer addSublayer:self.maskLayer];
    
    UIBezierPath *outerBorderPath = [UIBezierPath bezierPathWithRect:self.previewView.bounds];
    UIBezierPath *innerBorderPath = [UIBezierPath bezierPathWithRect:self.scanView.frame];
    [outerBorderPath appendPath:innerBorderPath];
    
    CAShapeLayer *scanRectLayer = [CAShapeLayer layer];
    scanRectLayer.fillRule = kCAFillRuleEvenOdd;
    scanRectLayer.path = outerBorderPath.CGPath;
    self.maskLayer.mask = scanRectLayer;
}

- (void)setupCaptureButton
{
    [self.view addSubview:self.captureButton];
    [self addCaptureButtonConstraints];
}

- (void)setupLivePhotoButton
{
    [self setImageForLivePhotoButton];
    [self.view addSubview:self.livePhotoButton];
    [self addLivePhotoButtonConstraints];
}

- (void)setupFlashButton
{
    [self.view addSubview:self.flashButton];
    [self addFlashButtonConstraints];
}

- (void)setupVideoFlashButton
{
    [self setImageForVideoFlashButton];
    [self.view addSubview:self.videoFlashButton];
    [self addVideoFlashButtonConstraints];
}

- (void)setupCameraButton
{
    [self.view addSubview:self.cameraButton];
    [self addCameraButtonConstraints];
}

- (void)setupTorchButton
{
    [self setImageForTorchButton];
    [self.scanView addSubview:self.torchButton];
    [self addTorchButtonConstraints];
}

- (void)setupAlbumButton
{
    [self.view addSubview:self.albumButton];
    [self addAlbumButtonConstraints];
}

- (void)setupSaveButton
{
    [self.saveView addSubview:self.saveButton];
    [self addSaveButtonConstraints];
}

- (void)setupCancelButton
{
    [self.saveView addSubview:self.cancelButton];
    [self addCancelButtonConstraints];
}

- (void)setupShareButton
{
    [self.saveView addSubview:self.shareButton];
    [self addShareButtonConstraints];
}

#pragma mark Add Constraints
- (void)addPreviewViewConstraints
{
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
}

- (void)addScanViewConstraints
{
    self.scanView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.scanView.widthAnchor constraintEqualToConstant:260].active = YES;
    [self.scanView.heightAnchor constraintEqualToAnchor:self.scanView.widthAnchor].active = YES;
    [self.scanView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.scanView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
}

- (void)addMarkViewConstraints
{
    self.markView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.markView.widthAnchor constraintEqualToConstant:12].active = YES;
    [self.markView.heightAnchor constraintEqualToConstant:8].active = YES;
    [self.markView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.markView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
}

- (void)addContainerViewConstraints
{
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.containerView.widthAnchor constraintEqualToConstant:CGRectGetWidth(self.containerView.bounds)].active = YES;
    [self.containerView.heightAnchor constraintEqualToConstant:CGRectGetHeight(self.containerView.bounds)].active = YES;
    [self.containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.containerView.bottomAnchor constraintEqualToAnchor:self.markView.topAnchor constant:-10].active = YES;
}

- (void)addSaveViewConstraints
{
    self.saveView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.saveView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.saveView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.saveView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.saveView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
}

- (void)addImageViewConstraints
{
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.imageView.topAnchor constraintEqualToAnchor:self.saveView.topAnchor].active = YES;
    [self.imageView.bottomAnchor constraintEqualToAnchor:self.saveView.bottomAnchor].active = YES;
    [self.imageView.leadingAnchor constraintEqualToAnchor:self.saveView.leadingAnchor].active = YES;
    [self.imageView.trailingAnchor constraintEqualToAnchor:self.saveView.trailingAnchor].active = YES;
}

- (void)addLivePhotoLabelConstraints
{
    self.livePhotoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.livePhotoLabel.widthAnchor constraintEqualToConstant:44].active = YES;
    [self.livePhotoLabel.heightAnchor constraintEqualToConstant:44].active = YES;
    [self.livePhotoLabel.centerXAnchor constraintEqualToAnchor:self.imageView.centerXAnchor].active = YES;
    [self.livePhotoLabel.topAnchor constraintEqualToAnchor:self.imageView.topAnchor constant:20].active = YES;
}

- (void)addPlayerViewConstraints
{
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.playerView.topAnchor constraintEqualToAnchor:self.saveView.topAnchor].active = YES;
    [self.playerView.bottomAnchor constraintEqualToAnchor:self.saveView.bottomAnchor].active = YES;
    [self.playerView.leadingAnchor constraintEqualToAnchor:self.saveView.leadingAnchor].active = YES;
    [self.playerView.trailingAnchor constraintEqualToAnchor:self.saveView.trailingAnchor].active = YES;
}

- (void)addCaptureButtonConstraints
{
    self.captureButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.captureButton.widthAnchor constraintEqualToConstant:70].active = YES;
    [self.captureButton.heightAnchor constraintEqualToAnchor:self.captureButton.widthAnchor].active = YES;
    [self.captureButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.captureButton.bottomAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:-10].active = YES;
}

- (void)addLivePhotoButtonConstraints
{
    self.livePhotoButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.livePhotoButton.widthAnchor constraintEqualToConstant:44].active = YES;
    [self.livePhotoButton.heightAnchor constraintEqualToAnchor:self.livePhotoButton.widthAnchor].active = YES;
    [self.livePhotoButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.livePhotoButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20].active = YES;
}

- (void)addFlashButtonConstraints
{
    self.flashButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.flashButton.widthAnchor constraintEqualToAnchor:self.livePhotoButton.widthAnchor].active = YES;
    [self.flashButton.heightAnchor constraintEqualToAnchor:self.livePhotoButton.heightAnchor].active = YES;
    [self.flashButton.centerYAnchor constraintEqualToAnchor:self.livePhotoButton.centerYAnchor].active = YES;
    [self.flashButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20].active = YES;
}

- (void)addVideoFlashButtonConstraints
{
    self.videoFlashButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.videoFlashButton.widthAnchor constraintEqualToAnchor:self.livePhotoButton.widthAnchor].active = YES;
    [self.videoFlashButton.heightAnchor constraintEqualToAnchor:self.livePhotoButton.heightAnchor].active = YES;
    [self.videoFlashButton.centerYAnchor constraintEqualToAnchor:self.livePhotoButton.centerYAnchor].active = YES;
    [self.videoFlashButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20].active = YES;
}

- (void)addCameraButtonConstraints
{
    self.cameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.cameraButton.widthAnchor constraintEqualToAnchor:self.livePhotoButton.widthAnchor].active = YES;
    [self.cameraButton.heightAnchor constraintEqualToAnchor:self.livePhotoButton.heightAnchor].active = YES;
    [self.cameraButton.centerYAnchor constraintEqualToAnchor:self.livePhotoButton.centerYAnchor].active = YES;
    [self.cameraButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20].active = YES;
}

- (void)addTorchButtonConstraints
{
    self.torchButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.torchButton.widthAnchor constraintEqualToConstant:60].active = YES;
    [self.torchButton.heightAnchor constraintEqualToAnchor:self.torchButton.widthAnchor].active = YES;
    [self.torchButton.centerXAnchor constraintEqualToAnchor:self.scanView.centerXAnchor].active = YES;
    [self.torchButton.bottomAnchor constraintEqualToAnchor:self.scanView.bottomAnchor constant:-10].active = YES;
}

- (void)addAlbumButtonConstraints
{
    self.albumButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.albumButton.widthAnchor constraintEqualToAnchor:self.livePhotoButton.widthAnchor].active = YES;
    [self.albumButton.heightAnchor constraintEqualToAnchor:self.livePhotoButton.heightAnchor].active = YES;
    [self.albumButton.centerYAnchor constraintEqualToAnchor:self.livePhotoButton.centerYAnchor].active = YES;
    [self.albumButton.trailingAnchor constraintEqualToAnchor:self.cameraButton.trailingAnchor].active = YES;
}

- (void)addSaveButtonConstraints
{
    self.saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.saveButton.widthAnchor constraintEqualToConstant:60].active = YES;
    [self.saveButton.heightAnchor constraintEqualToAnchor:self.saveButton.widthAnchor].active = YES;
    [self.saveButton.centerXAnchor constraintEqualToAnchor:self.saveView.centerXAnchor].active = YES;
    [self.saveButton.bottomAnchor constraintEqualToAnchor:self.saveView.bottomAnchor constant:-12].active = YES;
}

- (void)addCancelButtonConstraints
{
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.cancelButton.widthAnchor constraintEqualToConstant:44].active = YES;
    [self.cancelButton.heightAnchor constraintEqualToAnchor:self.cancelButton.widthAnchor].active = YES;
    [self.cancelButton.topAnchor constraintEqualToAnchor:self.saveView.topAnchor constant:20].active = YES;
    [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.saveView.leadingAnchor constant:20].active = YES;
}

- (void)addShareButtonConstraints
{
    self.shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.shareButton.widthAnchor constraintEqualToAnchor:self.cancelButton.widthAnchor].active = YES;
    [self.shareButton.heightAnchor constraintEqualToAnchor:self.cancelButton.heightAnchor].active = YES;
    [self.shareButton.centerYAnchor constraintEqualToAnchor:self.cancelButton.centerYAnchor].active = YES;
    [self.shareButton.trailingAnchor constraintEqualToAnchor:self.saveView.trailingAnchor constant:-20].active = YES;
}

#pragma mark Getter
// hides status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (PreviewView *)previewView
{
    if (!_previewView) {
        _previewView = [[PreviewView alloc] init];
    }
    
    return _previewView;
}

- (ScanView *)scanView
{
    if (!_scanView) {
        _scanView = [[ScanView alloc] init];
        _scanView.backgroundColor = [UIColor clearColor];
    }
    
    return _scanView;
}

- (UIView *)focusView
{
    if (!_focusView) {
        _focusView = [[FocusView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _focusView.backgroundColor = [UIColor clearColor];
        _focusView.hidden = YES;
    }
    
    return _focusView;
}

- (MarkView *)markView
{
    if (!_markView) {
        _markView = [[MarkView alloc] init];
        _markView.backgroundColor = [UIColor clearColor];
    }
    
    return _markView;
}

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 30)];
        _containerView.backgroundColor = [UIColor clearColor];
    }
    
    return _containerView;
}

- (UIPickerView *)pickerView
{
    if (!_pickerView) {
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 30, 600)];
        _pickerView.backgroundColor = [UIColor clearColor];
    }
    
    return _pickerView;
}

- (UIView *)saveView
{
    if (!_saveView) {
        _saveView = [[UIView alloc] init];
        _saveView.backgroundColor = [UIColor blackColor];
    }
    
    return _saveView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor blackColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }

    return _imageView;
}

- (UILabel *)livePhotoLabel
{
    if (!_livePhotoLabel) {
        _livePhotoLabel = [[UILabel alloc] init];
        _livePhotoLabel.text = @"LIVE";
        _livePhotoLabel.textColor = [UIColor whiteColor];
    }
    
    return _livePhotoLabel;
}

- (PlayerView *)playerView
{
    if (!_playerView) {
        _playerView = [[PlayerView alloc] init];
        _playerView.backgroundColor = [UIColor blackColor];
    }
    
    return _playerView;
}

- (UIButton *)captureButton
{
    if (!_captureButton) {
        _captureButton = [[UIButton alloc] init];
    }
    
    return _captureButton;
}

- (PhotoButton *)photoButton
{
    if (!_photoButton) {
        _photoButton = [[PhotoButton alloc] initWithFrame:self.captureButton.bounds];
        _photoButton.backgroundColor = [UIColor clearColor];
        [_photoButton addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _photoButton;
}

- (VideoButton *)videoButton
{
    if (!_videoButton) {
        _videoButton = [[VideoButton alloc] initWithFrame:self.captureButton.bounds];
        _videoButton.backgroundColor = [UIColor clearColor];
        [_videoButton addTarget:self action:@selector(recordVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _videoButton;
}

- (RewindButton *)rewindButton
{
    if (!_rewindButton) {
        _rewindButton = [[RewindButton alloc] initWithFrame:self.captureButton.bounds];
        _rewindButton.backgroundColor = [UIColor clearColor];
        [_rewindButton addTarget:self action:@selector(recordVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _rewindButton;
}

- (UIButton *)scanQRCodeButton
{
    if (!_scanQRCodeButton) {
        _scanQRCodeButton = [[UIButton alloc] initWithFrame:CGRectZero];
    }
    
    return _scanQRCodeButton;
}

- (StopButton *)stopButton
{
    if (!_stopButton) {
        _stopButton = [[StopButton alloc] initWithFrame:self.captureButton.bounds];
        _stopButton.backgroundColor = [UIColor clearColor];
        [_stopButton addTarget:self action:@selector(stopRecording:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _stopButton;
}

- (SaveButton *)saveButton
{
    if (!_saveButton) {
        _saveButton = [[SaveButton alloc] initWithFrame:self.captureButton.bounds];
        _saveButton.backgroundColor = [UIColor clearColor];
        [_saveButton addTarget:self action:@selector(save:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _saveButton;
}

- (UIButton *)livePhotoButton
{
    if (!_livePhotoButton) {
        _livePhotoButton = [[UIButton alloc] init];
        [_livePhotoButton addTarget:self action:@selector(toggleLivePhotoMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _livePhotoButton;
}

- (UIButton *)flashButton
{
    if (!_flashButton) {
        _flashButton = [[UIButton alloc] init];
        
        switch (self.cameraViewController.flashMode) {
            case AVCaptureFlashModeAuto:
                [_flashButton setImage:[UIImage imageNamed:@"flashAuto"] forState:UIControlStateNormal];
                break;
            case AVCaptureFlashModeOn:
                [_flashButton setImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
                break;
            case AVCaptureFlashModeOff:
                [_flashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
        
        [_flashButton addTarget:self action:@selector(toggleFlashMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _flashButton;
}

- (UIButton *)videoFlashButton
{
    if (!_videoFlashButton) {
        _videoFlashButton = [[UIButton alloc] init];
        [_videoFlashButton addTarget:self action:@selector(toggleVideoFlashMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _videoFlashButton;
}

- (UIButton *)torchButton
{
    if (!_torchButton) {
        _torchButton = [[UIButton alloc] init];
        [_torchButton addTarget:self action:@selector(toggleTorchMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _torchButton;
}

- (UIButton *)cameraButton
{
    if (!_cameraButton) {
        _cameraButton = [[UIButton alloc] init];
        [_cameraButton setImage:[UIImage imageNamed:@"switchCamera"] forState:UIControlStateNormal];
        [_cameraButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cameraButton;
}

- (UIButton *)albumButton
{
    if (!_albumButton) {
        _albumButton = [[UIButton alloc] init];
//        _albumButton.hidden = YES;
        [_albumButton setImage:[UIImage imageNamed:@"album"] forState:UIControlStateNormal];
        [_albumButton addTarget:self action:@selector(readingFromAlbum:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _albumButton;
}

- (UIButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [[UIButton alloc] init];
        [_cancelButton setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cancelButton;
}

- (UIButton *)shareButton
{
    if (!_shareButton) {
        _shareButton = [[UIButton alloc] init];
        [_shareButton setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
        [_shareButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _shareButton;
}

- (NSArray *)itemsArray
{
    if (!_itemsArray) {
        _itemsArray = @[@"倒播", @"照片", @"视频", @"扫码"];
    }
    
    return _itemsArray;
}

- (NSMutableArray *)captureButtonsArray
{
    if (!_captureButtonsArray) {
        _captureButtonsArray = [NSMutableArray array];
        
        [_captureButtonsArray addObject:self.rewindButton];
        [_captureButtonsArray addObject:self.photoButton];
        [_captureButtonsArray addObject:self.videoButton];
        [_captureButtonsArray addObject:self.scanQRCodeButton];
    }
    
    return _captureButtonsArray;
}

@end
