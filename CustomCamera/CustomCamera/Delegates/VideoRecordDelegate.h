//
//  VideoRecordDelegate.h
//  CustomCamera
//
//  Created by pro648 on 2018/8/5.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "CustomCameraDelegate.h"

@interface VideoRecordDelegate : NSObject <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) id<CustomCameraDelegate> delegate;

@end
