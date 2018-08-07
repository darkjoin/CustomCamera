//
//  PlayerView.m
//  CustomCamera
//
//  Created by pro648 on 2018/8/3.
//  Copyright © 2018 darkgm. All rights reserved.
//

#import "PlayerView.h"

@implementation PlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
