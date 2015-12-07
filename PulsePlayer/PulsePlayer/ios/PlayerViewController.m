//
//  PlayerViewController.m
//  PulsePlayer
//
//  Created by Jacques du Toit on 12/10/15.
//  Copyright © 2015 Ooyala. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "PlayerViewController.h"
#import "AVAsset+Preloading.h"


typedef enum : NSUInteger {
  PlayerStateIdle = 0,
  PlayerStateLoading = 1,
  PlayerStatePlaying = 2
} PlayerState;


/*
 An View Controller for playing back video on iOS devices like the iPad and iPhone.
 This supports the new picture-in-picture mode.
*/
@interface PlayerViewController () <OOPulseSessionDelegate, UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate> {
  // Keeps tracks of AVPlayer timePeriod observer
  id playerPeriodicObserver;

  // Used to restore the playback rate when returning from background mode
  float playbackRateBeforeBackground;
}

@property (strong, nonatomic) AVPlayerViewController *playerViewController;

@property (assign, nonatomic) PlayerState state;
@property (assign, nonatomic) BOOL pictureInPictureActive;

@property (strong, nonatomic) id<OOPulseSession> session;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *contentItem;
@property (strong, nonatomic) AVAsset *contentAsset;
@property (strong, nonatomic) AVAsset *adAsset;

@property (weak, nonatomic)   id<OOPulseVideoAd> ad;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation PlayerViewController

- (instancetype)init
{
  self = [super init];
  if (self) {
    _playerViewController = [[AVPlayerViewController alloc] init];
    _playerViewController.delegate = self;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self initializePlayer];
  [self initializeView];

  [self observeAppState];
}

- (void)initializePlayer
{
  self.player = [[AVPlayer alloc] init];

  // Get a periodic notification while player is playing
  __weak PlayerViewController *weakSelf = self;
  playerPeriodicObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC)
                                                                     queue:nil
                                                                usingBlock:^(CMTime time) {
                                                                  [weakSelf onPlayback:time];
                                                                }];

  // Get notified when a AVPlayerItem finished playback
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onPlaybackFinished:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:nil];
}

- (void)initializeView
{
  // Create a AVPlayerViewController that will be responsible for displaying video
  self.playerViewController.player = self.player;
  [self addChildViewController:self.playerViewController];
  [self.view addSubview:self.playerViewController.view];
  [self.playerViewController.view setFrame:self.view.frame];

  // Create a loading indicator, and add it to our view
  self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.view.frame];
  self.activityIndicatorView.hidesWhenStopped = YES;
  self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
  [self.view addSubview:self.activityIndicatorView];

  // Add click-through tap recognizer
  UIGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc]
                                     initWithTarget:self action:@selector(onVideoTapped)];
  recognizer.delegate = self;
  [self.view addGestureRecognizer:recognizer];
}

- (void)observeAppState
{
  // Get notified when app enters/returns from the background
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationWillEnterForeground)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidEnterBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  // If the user dismisses the view we want to stop the video and get rid of
  // the session. Activating picture in picture mode will also dismiss the view
  // controller, but in that case we do not want to stop the player.
  if (self.isBeingDismissed && !self.pictureInPictureActive) {
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.session = nil;
  }

  [super viewWillDisappear:animated];
}

- (void)playContentWithURL:(NSURL *)url contentMetadata:(VPContentMetadata *)contentMetadata requestSettings:(VPRequestSettings *)requestSettings
{
  [self.player replaceCurrentItemWithPlayerItem:nil];
  [self.player cancelPendingPrerolls];
  self.ad = nil;
  self.adAsset = nil;
  self.contentItem = nil;
  self.contentAsset = [AVAsset assetWithURL:url];
  [self.contentAsset preload];

  [self setIsLoading:YES];
  self.session = [OOPulse sessionWithContentMetadata:contentMetadata requestSettings:requestSettings];
  [self.session startSessionWithDelegate:self];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.player removeTimeObserver:playerPeriodicObserver];
}


#pragma mark - Video playback support

- (void)play:(AVPlayerItem *)item
{
  [self.player replaceCurrentItemWithPlayerItem:item];
  [self.player play];
}

// Returns YES is asset is the same one as in the current player item.
- (BOOL)isAssetActive:(AVAsset *)asset
{
  // For the asset to be active it must non-null, and equal to the
  // the current player item's asset
  return asset && [self.player.currentItem asset] == asset;
}

// Returns YES if asset is currently playing in the video player.
- (BOOL)isAssetPlaying:(AVAsset *)asset
{
  return [self isAssetActive:asset] && self.player.rate > 0;
}

// Returns YES if asset is currently paused in the video player.
- (BOOL)isAssetPaused:(AVAsset *)asset
{
  return [self isAssetActive:asset] && self.player.rate == 0;
}

#pragma mark - Events observers

- (void)applicationDidEnterBackground
{
  playbackRateBeforeBackground = self.player.rate;
  if (!self.pictureInPictureActive && [self isAssetPlaying:self.adAsset]) {
    [self.player pause];
    [self.ad adPaused];
  }
}

- (void)applicationWillEnterForeground
{
  if (playbackRateBeforeBackground > 0 && [self isAssetPaused:self.adAsset]) {
    [self.ad adResumed];
  }
  [self.player setRate:playbackRateBeforeBackground];
}

- (void)onPlaybackFinished:(NSNotification *)notification
{
  // Execute on main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([notification.object asset] == self.adAsset) {
      self.adAsset = nil;
      [self.ad adFinished];
    }
    else if ([notification.object asset] == self.contentAsset) {
      [self.session contentFinished];
    }
  });
}

- (void)onPlayback:(CMTime)time
{
  // Ensure that we are currently playing either the content or an ad.
  // We need to check this because sometimes the periodic time observer callbacks
  // are already in the dispatch queue when we change the video player state.
  if ([self isAssetPlaying:self.adAsset]
      || [self isAssetPlaying:self.contentAsset]) {

    if (self.state == PlayerStateLoading) {
      if (self.adAsset)
        [self.ad adStarted];
      else
        [self.session contentStarted];
      [self setIsLoading:NO];
    }
    else {
      NSTimeInterval position = (NSTimeInterval)time.value/time.timescale;

      if (self.adAsset)
        [self.ad adPositionChanged:position];
      else
        [self.session contentPositionChanged:position];
    }
  }
}

#pragma mark - OOPulseSessionDelegate

- (void)startContentPlayback
{
  NSLog(@"OOPulseSessionDelegate.startContentPlayback");

  [self.player pause];
  [self setIsLoading:YES];

  [self setControlsVisible:YES];
  [self.playerViewController setAllowsPictureInPicturePlayback:YES];

  if (self.contentItem)
    [self play:self.contentItem];
  else {
    [self.contentAsset preloadWithTimeout:15 success:^(AVAsset *asset) {
      self.contentItem = [AVPlayerItem playerItemWithAsset:asset];
      [self play:self.contentItem];
    } failure:^(OOPulseAdError error) {
      [self dismissViewControllerAnimated:YES completion:nil];
    }];
  }
}

- (void)startAdBreak
{
  NSLog(@"OOPulseSessionDelegate.startAdBreak");

  [self setControlsVisible:NO];
  [self.playerViewController setAllowsPictureInPicturePlayback:NO];

  [self setIsLoading:YES];
}

- (void)startAdPlaybackWithAd:(id<OOPulseVideoAd>)ad timeout:(NSTimeInterval)timeout
{
  NSLog(@"OOPulseSessionDelegate.startAdPlaybackWithAd: %@", ad);

  // Use the first media file. In a production app the asset selection algorithm
  // should select the ideal media file based on size, bandwidth and format
  // considerations.
  self.adAsset = [AVAsset assetWithURL:[ad.mediaFiles.firstObject URL]];

  [self.player pause];
  [self setIsLoading:YES];

  [self.adAsset preloadWithTimeout:timeout success:^(AVAsset *asset) {
    self.ad = ad;
    [self play:[AVPlayerItem playerItemWithAsset:asset]];
  } failure:^(OOPulseAdError error) {
    self.adAsset = nil;
    [ad adFailedWithError:error];
  }];
}

- (void)sessionEnded
{
  NSLog(@"OOPulseSessionDelegate.sessionEnded");

  if (!self.isBeingDismissed) {
    [self dismissViewControllerAnimated:YES completion:^{}];
  }
}

- (void)illegalOperationOccurredWithError:(NSError *)error
{
  NSLog(@"Illegal operation occurred: %@", error);;

#if DEBUG
  // In debug mode we throw on illegal operations in order to find and
  // correct mistakes in the integration.
  @throw [NSException exceptionWithName:@"Illegal operation" reason:[error description] userInfo:nil];
#else
  // Don't know how to recover from this, stop the session and continue
  // with the content.
  [self.session stopSession];
  self.session = nil;
  [self startContentPlayback];
#endif
}

#pragma mark - UI

- (void)setControlsVisible:(BOOL)visible
{
  // This is a hacky way of hiding the controls. In a real app your probably
  // want to use your own controls anyway.
  UIView *parent = self.playerViewController.view.subviews[0];
  for (long i = parent.subviews.count - 1; i > 0; i--) {
      if ([parent.subviews[i] isMemberOfClass:[UIView class]]) {
        parent.subviews[i].hidden = !visible;
        return;
      }
    }
  }

- (void)setIsLoading:(BOOL)loading
{
  if (loading)
    [self.activityIndicatorView startAnimating];
  else
    [self.activityIndicatorView stopAnimating];

  [self.playerViewController.view setHidden:loading];
  self.state = loading ? PlayerStateLoading : PlayerStatePlaying;
}

- (void)onVideoTapped
{
  // If we have an ad asset and it is playing, then trigger clickthrough
  if ([self isAssetPlaying:self.adAsset]) {
    if ([self.ad clickthroughURL]) {
      [self.ad adClickThroughTriggered];
      [[UIApplication sharedApplication] openURL:[self.ad clickthroughURL]];
    }
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  return YES;
}

#pragma mark - AVPlayerViewControllerDelegate

- (void)playerViewControllerWillStartPictureInPicture:(AVPlayerViewController *)playerViewController
{
  self.pictureInPictureActive = YES;
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
  if ([self.delegate respondsToSelector:@selector(playerViewController:restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:)]) {
    [self.delegate playerViewController:self restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:completionHandler];
  }
}

- (void)playerViewControllerWillStopPictureInPicture:(AVPlayerViewController *)playerViewController
{
  self.pictureInPictureActive = NO;
}

@end
