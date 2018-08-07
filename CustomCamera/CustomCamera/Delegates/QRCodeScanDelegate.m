//
//  QRCodeScanDelegate.m
//  CustomCamera
//
//  Created by pro648 on 2018/8/5.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "QRCodeScanDelegate.h"

@interface QRCodeScanDelegate ()

@property (nonatomic, strong) NSString *message;

@end

@implementation QRCodeScanDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    if (metadataObjects != nil && metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
        if ([[metadataObject type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *message = [metadataObject stringValue];
            self.message = message;
            
            if ([self.delegate respondsToSelector:@selector(finishScanQRCode)]) {
                [self.delegate finishScanQRCode];
            }
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.message forKey:@"QRCodeMessage"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kDidOutputMetadataObjects" object:nil userInfo:userInfo];
        }
    }
}

@end
