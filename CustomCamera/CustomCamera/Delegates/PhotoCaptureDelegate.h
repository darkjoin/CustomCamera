//
//  PhotoCaptureDelegate.h
//  CustomCamera
//
//  Created by pro648 on 2018/7/20.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "CustomCameraDelegate.h"

@interface PhotoCaptureDelegate : NSObject <AVCapturePhotoCaptureDelegate>

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)(void))willCapturePhotoAnimation livePhotoCaptureHandler:(void (^)(BOOL capturing))livePhotoCaptureHandler completionHandler:(void (^)(PhotoCaptureDelegate *photoCaptureDelegate))completionHandler;

@property (nonatomic, weak) id<CustomCameraDelegate> delegate;

@property (nonatomic, readonly) AVCapturePhotoSettings *requestedPhotoSettings;

@end
