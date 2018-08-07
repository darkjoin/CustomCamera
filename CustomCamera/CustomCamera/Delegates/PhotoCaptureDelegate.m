//
//  PhotoCaptureDelegate.m
//  CustomCamera
//
//  Created by pro648 on 2018/7/20.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "PhotoCaptureDelegate.h"

@interface PhotoCaptureDelegate ()

@property (nonatomic, readwrite) AVCapturePhotoSettings *requestedPhotoSettings;
@property (nonatomic, copy) void (^willCapturePhotoAnimation)(void);
@property (nonatomic, copy) void (^livePhotoCaptureHandler)(BOOL capturing);
@property (nonatomic, copy) void (^completionHandler)(PhotoCaptureDelegate *photoCaptureDelegate);

@property (nonatomic, strong) NSData *photoData;
@property (nonatomic, strong) NSURL *livePhotoCompanionMovieURL;

@end

@implementation PhotoCaptureDelegate

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)(void))willCapturePhotoAnimation livePhotoCaptureHandler:(void (^)(BOOL))livePhotoCaptureHandler completionHandler:(void (^)(PhotoCaptureDelegate *))completionHandler
{
    self = [super init];
    if (self) {
        self.requestedPhotoSettings = requestedPhotoSettings;
        self.willCapturePhotoAnimation = willCapturePhotoAnimation;
        self.livePhotoCaptureHandler = livePhotoCaptureHandler;
        self.completionHandler = completionHandler;
    }
    
    return self;
}

- (void)didFinish
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.livePhotoCompanionMovieURL.path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.livePhotoCompanionMovieURL.path error:&error];
        
        if (error) {
            NSLog(@"Could not remove file at url: %@", self.livePhotoCompanionMovieURL.path);
        }
    }
    
    self.completionHandler(self);
}

#pragma mark AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    if ((resolvedSettings.livePhotoMovieDimensions.width > 0) && (resolvedSettings.livePhotoMovieDimensions.height > 0)) {
        self.livePhotoCaptureHandler(YES);
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    self.willCapturePhotoAnimation();
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    if (error != nil) {
        NSLog(@"Error capture photo: %@", error);
        return;
    }
    
    self.photoData = [photo fileDataRepresentation];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    self.livePhotoCaptureHandler(NO);
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
    if (error != nil) {
        NSLog(@"Error processing live photo companion movie: %@", error);
        return;
    }
    
    self.livePhotoCompanionMovieURL = outputFileURL;
}


- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
    if (error != nil) {
        NSLog(@"Error capturing photo: %@", error);
        [self didFinish];
        return;
    }
    
    if (self.photoData == nil) {
        NSLog(@"No photo data resource");
        [self didFinish];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(finishCapturePhotoWithPhotoData:andWithLivePhotoFileURL:)]) {
        [self.delegate finishCapturePhotoWithPhotoData:self.photoData andWithLivePhotoFileURL:self.livePhotoCompanionMovieURL];
    }
}


@end
