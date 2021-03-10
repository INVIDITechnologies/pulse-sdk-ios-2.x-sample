//
//  SkinViewController
//  PulsePlayer
//
//  Created by Steve on 22/06/16.
//  Copyright © 2016 Ooyala. All rights reserved.
//

#define CONTROLS_HIDE_TIMEOUT (4.0 /*seconds*/)

#define ICON_PLAY  @"h"
#define ICON_PAUSE @"g"
#define ICON_FULLSCREEN @"i"
#define ICON_EXIT_FULLSCREEN @"j"

#import <AVFoundation/AVFoundation.h>
#import "SkinViewController.h"
#import <Pulse/OOPlayerState.h>

@interface SkinViewController() {
  // Keeps tracks of AVPlayer timePeriod observer
  id playerPeriodicObserver;
  bool wasPlayingBeforeSlide;
  NSTimer *hideTimer;
}

@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isFullscreen;

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIView *closeButtonView;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *fullscreenButton;
@property (weak, nonatomic) IBOutlet UIView *controlsContainerView;
@property (weak, nonatomic) IBOutlet UISlider *positionSlider;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicatorView;

- (IBAction)playPauseButtonPressed;
- (IBAction)closeButtonPressed;
- (IBAction)videoPressed;
- (IBAction)fullscreenButtonPressed;

@end

@implementation SkinViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self showControls];
  
  NSLog(@"SkinViewController: init playerLayer");
  self.requiresLinearPlayback = NO;
  self.playPauseButton.titleLabel.text = ICON_PLAY;
  self.fullscreenButton.titleLabel.text = ICON_FULLSCREEN;
  self.isFullscreen = false;
  self.positionSlider.continuous = YES;
  [self.positionSlider addTarget:self action:@selector(onSliderEvent:withEvent:)
                forControlEvents: UIControlEventValueChanged | UIControlEventTouchCancel];
  
  self.playerLayer = [[AVPlayerLayer alloc] init];
  self.playerLayer.player = self.player;
  [self.view.layer insertSublayer:self.playerLayer atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  // Auto - play
  [self play];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  self.playerLayer.frame = self.view.bounds;
}

- (void)viewWillDisappear:(BOOL)animated
{
  if (self.isBeingDismissed) {
    [self.player replaceCurrentItemWithPlayerItem:nil];
  }
  
  [super viewWillDisappear:animated];
}

- (void)dealloc {
  [self scheduleHideControls];
  self.player = nil;
}

#pragma mark - API

- (void)setPlayer:(AVPlayer *)player
{
  if (player != self.player) {
    if (_player) {
      // Deinit old player
      [_player removeTimeObserver:playerPeriodicObserver];
    
    }
    _player = player;
    
    if (_player) {
      // Init new player
      __weak SkinViewController *weakSelf = self;
      playerPeriodicObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC)
                                                                     queue:nil
                                                                usingBlock:^(CMTime time) {
                                                                  [weakSelf onPlayback:time];
                                                                }];
      
    }
  }
}

- (void)setRequiresLinearPlayback:(BOOL)requiresLinearPlayback
{
  _requiresLinearPlayback = requiresLinearPlayback;
  
  if (requiresLinearPlayback) {
    self.positionSlider.userInteractionEnabled = NO;
    self.positionSlider.enabled = NO;
  } else {
    self.positionSlider.userInteractionEnabled = YES;
    self.positionSlider.enabled = YES;
  }
}

- (void)seekToTime:(NSTimeInterval)time
{
  CMTimeScale scale = self.player.currentItem.asset.duration.timescale;
  CMTime tolerance = CMTimeMakeWithSeconds(1.0f/15.0f, scale);
  [self.player seekToTime:CMTimeMakeWithSeconds(self.positionSlider.value, scale)
          toleranceBefore:tolerance
           toleranceAfter:tolerance];
}

- (void)setLoading:(BOOL)loading
{
  _loading = loading;
  if (loading) {
    self.playerLayer.hidden = YES;
    [self.loadingIndicatorView startAnimating];
  }
  else {
    self.playerLayer.hidden = NO;
    [self.loadingIndicatorView stopAnimating];
  }
}

#pragma mark - Showing hiding of controls


- (void)unscheduleHideControls
{
  if (hideTimer) {
    [hideTimer invalidate];
  }
  hideTimer = nil;
}

- (void)scheduleHideControls
{
  [self unscheduleHideControls];
  hideTimer = [NSTimer scheduledTimerWithTimeInterval:CONTROLS_HIDE_TIMEOUT
                                               target:self
                                             selector:@selector(hideControls)
                                             userInfo:nil
                                              repeats:NO];
}

- (void)hideControls
{
  [self unscheduleHideControls];
  self.controlsContainerView.hidden = YES;
}


- (void)showControls
{
  [self unscheduleHideControls];
  self.controlsContainerView.hidden = NO;
  [self scheduleHideControls];
}

- (void)showControlsAlways
{
  self.controlsContainerView.hidden = NO;
  [self unscheduleHideControls];
}

- (void)toggleControls
{
  if (self.controlsContainerView.hidden == YES) {
    [self showControls];
  } else {
    [self hideControls];
  }
}

- (void)disableCloseButton
{
  [self.closeButtonView setHidden:YES];
}

#pragma mark - Playback

- (void)pause
{
  self.isPlaying = false;
  [self.player pause];
  [self.playPauseButton setTitle:ICON_PLAY forState:UIControlStateNormal];
}

- (void)play
{
  self.isPlaying = true;
  [self.player play];
  [self.playPauseButton setTitle:ICON_PAUSE forState:UIControlStateNormal];
}

- (void)enterFullscreen
{
  self.isFullscreen = true;
    if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
        [[UIDevice currentDevice] setValue:
         [NSNumber numberWithInteger: UIInterfaceOrientationLandscapeRight]
                                    forKey:@"orientation"];
    }
    if ([self.delegate respondsToSelector:@selector(playerStateChanged:)])
    [self.delegate playerStateChanged:OOPlayerStateFULLSCREEN];
    [self.fullscreenButton setTitle:ICON_EXIT_FULLSCREEN forState:UIControlStateNormal];
}

- (void)exitFullscreen
{
  self.isFullscreen = false;
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        [[UIDevice currentDevice] setValue:
         [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                    forKey:@"orientation"];
    }
    if ([self.delegate respondsToSelector:@selector(playerStateChanged:)])
    [self.delegate playerStateChanged:OOPlayerStateNORMAL];
    [self.fullscreenButton setTitle:ICON_FULLSCREEN forState:UIControlStateNormal];
}

#pragma mark - Events

- (void)onSliderEvent:(UISlider*)slider withEvent:(UIEvent *)e
{
  UITouch *touch = [e.allTouches anyObject];
  if (touch.phase == UITouchPhaseBegan) {
    [self unscheduleHideControls];
    wasPlayingBeforeSlide = self.isPlaying;
    if (wasPlayingBeforeSlide) {
      [self pause];
    }
  }
  else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
    [self scheduleHideControls];
    if (wasPlayingBeforeSlide) {
      [self play];
    }
  }
  else if (touch.phase == UITouchPhaseMoved) {
    [self seekToTime:self.positionSlider.value];
  }
}

- (void)onPlayback:(CMTime)time
{
  if (abs(self.player.currentItem.duration.timescale) < 0.1) return;
  
  NSTimeInterval position = (NSTimeInterval)time.value/ time.timescale;
  NSTimeInterval duration  = self.player.currentItem.duration.value / self.player.currentItem.duration.timescale;
  self.currentTimeLabel.text = [self stringForTime:position];
  self.totalTimeLabel.text = [self stringForTime:duration];
  self.positionSlider.minimumValue = 0;
  self.positionSlider.maximumValue = duration;
  [self.positionSlider setValue:position animated:YES];
  
  if ([self.delegate respondsToSelector:@selector(playbackPositionChanged:)]) {
    [self.delegate playbackPositionChanged:position];
  }
}
- (IBAction)playPauseButtonPressed
{
  if (self.isPlaying) {
    if ([self.delegate respondsToSelector:@selector(userPausedVideo)])
      [self.delegate userPausedVideo];
    [self pause];
  } else {
    if ([self.delegate respondsToSelector:@selector(userResumedVideo)])
      [self.delegate userResumedVideo];
    [self play];
  }
}

- (IBAction)closeButtonPressed {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)fullscreenButtonPressed {
    if (self.isFullscreen) {
        [self exitFullscreen];
    } else {
        [self enterFullscreen];
    }
}

- (IBAction)videoPressed {
  if (self.controlsContainerView.hidden) {
    
  }
  if ([self.delegate respondsToSelector:@selector(userTappedVideo)]) {
    [self.delegate userTappedVideo];
  }
}

#pragma mark - Helpers

- (NSString *)stringForTime:(NSTimeInterval)time
{
  int hours = floor(time / 60 / 60);
  int minutes = floor((time - hours * 3600) / 60);
  int seconds = floor((time - hours * 3600 - minutes * 60));
  if (hours > 0)
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
  return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}


@end
