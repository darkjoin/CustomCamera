//
//  MainViewController.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/19.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "MainViewController.h"
#import "CameraViewController.h"

#import "MarkView.h"
#import "PhotoButton.h"
#import "VideoButton.h"
#import "RewindButton.h"
#import "StopButton.h"

@interface MainViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) CameraViewController *cameraViewController;

@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) MarkView *markView;
@property (nonatomic, strong) UIView *containerView;    // container for picker view
@property (nonatomic, strong) UIPickerView *pickerView;

@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, strong) PhotoButton *photoButton;
@property (nonatomic, strong) VideoButton *videoButton;
@property (nonatomic, strong) StopButton *stopButton;
@property (nonatomic, strong) RewindButton *rewindButton;
@property (nonatomic, strong) UIButton *scanQRCodeButton;

@property (nonatomic, strong) UIButton *livePhotoButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *cameraButton;

@property (nonatomic, strong) NSArray *itemsArray;
@property (nonatomic, strong) NSMutableArray *captureButtonsArray;

@end

@implementation MainViewController

#pragma mark Getter
// hides status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIView *)previewView
{
    if (!_previewView) {
//        _previewView = [[UIView alloc] init];
        _previewView = [[UIView alloc] initWithFrame:self.view.bounds];
//        _previewView.backgroundColor = [UIColor clearColor];
    }
    
    return _previewView;
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
        [_rewindButton addTarget:self action:@selector(recordRewindVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _rewindButton;
}

- (UIButton *)scanQRCodeButton
{
    if (!_scanQRCodeButton) {
        _scanQRCodeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _scanQRCodeButton.backgroundColor = [UIColor clearColor];
        [_scanQRCodeButton addTarget:self action:@selector(scanQRCode:) forControlEvents:UIControlEventTouchUpInside];
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

- (UIButton *)livePhotoButton
{
    if (!_livePhotoButton) {
        _livePhotoButton = [[UIButton alloc] init];
        [_livePhotoButton setImage:[UIImage imageNamed:@"livePhotoOff"] forState:UIControlStateNormal];
        [_livePhotoButton addTarget:self action:@selector(toggleLivePhotoMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _livePhotoButton;
}

- (UIButton *)flashButton
{
    if (!_flashButton) {
        _flashButton = [[UIButton alloc] init];
        [_flashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
        [_flashButton addTarget:self action:@selector(toggleFlashMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _flashButton;
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

- (NSArray *)itemsArray
{
    if (!_itemsArray) {
        _itemsArray = @[@"REWIND", @"PHOTO", @"VIDEO", @"SCAN-QRCODE"];
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

#pragma mark View Controller Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupUI];
    
    [self configureCameraViewController];
}

- (void)setupUI
{
    [self setupPreviewView];
    [self setupMarkView];
    [self setupContainerView];
    [self setupPickerView];
    [self setupCaptureButton];
    [self setupLivePhotoButton];
    [self setupFlashButton];
    [self setupCameraButton];
}

- (void)configureCameraViewController
{
    self.cameraViewController = [[CameraViewController alloc] init];
    
    [self.cameraViewController prepare];
    [self.cameraViewController displayPreviewOnView:self.previewView];
}

- (void)setupPreviewView
{
    [self.view addSubview:self.previewView];
    [self addPreviewViewConstraints];
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

- (void)setupCaptureButton
{
    [self.view addSubview:self.captureButton];
    [self addCaptureButtonConstraints];
}

- (void)setupLivePhotoButton
{
    [self.view addSubview:self.livePhotoButton];
    [self addLivePhotoButtonConstraints];
}

- (void)setupFlashButton
{
    [self.view addSubview:self.flashButton];
    [self addFlashButtonConstraints];
}

- (void)setupCameraButton
{
    [self.view addSubview:self.cameraButton];
    [self addCameraButtonConstraints];
}

#pragma mark Constraints
- (void)addPreviewViewConstraints
{
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
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
    [self.containerView.heightAnchor constraintEqualToConstant:30].active = YES;
    [self.containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.containerView.bottomAnchor constraintEqualToAnchor:self.markView.topAnchor constant:-10].active = YES;
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
    
    [self.livePhotoButton.widthAnchor constraintEqualToConstant:48].active = YES;
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

- (void)addCameraButtonConstraints
{
    self.cameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.cameraButton.widthAnchor constraintEqualToAnchor:self.livePhotoButton.widthAnchor].active = YES;
    [self.cameraButton.heightAnchor constraintEqualToAnchor:self.livePhotoButton.heightAnchor].active = YES;
    [self.cameraButton.centerYAnchor constraintEqualToAnchor:self.livePhotoButton.centerYAnchor].active = YES;
    [self.cameraButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20].active = YES;
}

#pragma mark Actions
- (void)capturePhoto:(UIButton *)photoButton
{
    [self.cameraViewController capturePhoto];
    
    NSLog(@"Capture photo");
}

- (void)recordVideo:(UIButton *)videoButton
{
    NSLog(@"Record video");
}

- (void)stopRecording:(UIButton *)stopButton
{
    NSLog(@"Stop recording");
}

- (void)recordRewindVideo:(UIButton *)rewindButton
{
    NSLog(@"Record rewind video");
}

- (void)scanQRCode:(UIButton *)scanQRCodeButton
{
    NSLog(@"Scan QRCode");
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
    
    NSLog(@"Toggle flash mode");
}

- (void)toggleLivePhotoMode:(UIButton *)livePhotoButton
{
    NSLog(@"Toggle live photo mode");
}

- (void)switchCamera:(UIButton *)cameraButton
{
    [self.cameraViewController switchCameras];
    
    NSLog(@"Switch camera");
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
    [self resetCaptureButtonWithButton:self.captureButtonsArray[row]];
}

@end
