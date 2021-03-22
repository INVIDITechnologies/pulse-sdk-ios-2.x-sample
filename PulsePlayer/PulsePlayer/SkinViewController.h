//
//  SkinViewController
//  PulsePlayer
//
//  Created by Steve on 22/06/16.
//  Copyright © 2016 Ooyala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <Pulse/OOPlayerState.h>

@protocol SkinViewControllerDelegate <NSObject>

- (void)playbackPositionChanged:(NSTimeInterval)position;
- (void)userTappedVideo;
- (void)userPausedVideo;
- (void)userResumedVideo;
- (void)playerStateChanged:(OOPlayerState)playerState;
- (void)playerVolumeChanged:(CGFloat)videoPlayerVolume;

@end

@interface SkinViewController : UIViewController

@property (strong, nonatomic) AVPlayer* player;

@property(nonatomic) BOOL requiresLinearPlayback;
@property(nonatomic, getter=isLoading) BOOL loading;

- (void)toggleControls;
- (void)showControls;
- (void)showControlsAlways;
- (void)hideControls;
- (void)disableCloseButton;
- (void)changeToPauseIcon;

@property (weak, nonatomic) IBOutlet UIView *contentOverlayView;

@property (weak, nonatomic) id<SkinViewControllerDelegate> delegate;
@end
