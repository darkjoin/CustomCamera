//
//  PlayerView.h
//  CustomCamera
//
//  Created by pro648 on 2018/8/3.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayerView : UIView

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic) AVPlayer *player;

@end
