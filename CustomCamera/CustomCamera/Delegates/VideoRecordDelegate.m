//
//  VideoRecordDelegate.m
//  CustomCamera
//
//  Created by pro648 on 2018/8/5.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "VideoRecordDelegate.h"

@interface VideoRecordDelegate ()

@end

@implementation VideoRecordDelegate

- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kDidStartRecordingNotification" object:nil userInfo:nil];
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kDidFinishRecordingNotification" object:nil userInfo:nil];
    
    dispatch_block_t cleanUpOutputFile = ^{
        if ( [[NSFileManager defaultManager] fileExistsAtPath:outputFileURL.path] ) {
            [[NSFileManager defaultManager] removeItemAtPath:outputFileURL.path error:NULL];
        }
    };
    
    BOOL success = YES;
    
    if (error) {
        NSLog(@"Movie file finishing error: %@", error);
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    
    if (success) {
        if ([self.delegate respondsToSelector:@selector(finishRecordingVideoWithMovieFileURL:)]) {
            [self.delegate finishRecordingVideoWithMovieFileURL:outputFileURL];
        }
    }
    else {
        cleanUpOutputFile();
    }
}

@end
