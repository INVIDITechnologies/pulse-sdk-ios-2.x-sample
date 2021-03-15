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
#import "SkipViewController.h"
#import "SkinViewController.h"
#import "PauseAdViewController.h"
#import "VideoItemCell.h"

typedef enum : NSUInteger {
  PlayerStateIdle = 0,
  PlayerStateLoading = 1,
  PlayerStatePlaying = 2
} PlayerState;


/*
 An View Controller for playing back video on iOS devices like the iPad and iPhone.
 This supports the new picture-in-picture mode.
*/
@interface PlayerViewController () <OOPulseSessionDelegate, SkipViewControllerDelegate, SkinViewControllerDelegate, PauseAdViewControllerDelegate> {

  // Used to restore the playback rate when returning from background mode
  float playbackRateBeforeBackground;
}

@property (strong, nonatomic) PauseAdViewController *pauseAdViewController;
@property (strong, nonatomic) SkipViewController *skipViewController;
@property (strong, nonatomic) SkinViewController *skinViewController;

@property (assign, nonatomic) PlayerState state;
@property (assign, nonatomic) BOOL pictureInPictureActive;

@property (strong, nonatomic) id<OOPulseSession> session;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *contentItem;
@property (strong, nonatomic) AVAsset *contentAsset;
@property (strong, nonatomic) AVAsset *adAsset;
@property (strong, nonatomic) VideoItem *videoItem;
@property (assign, nonatomic) BOOL isSessionExtensionRequested;
@property (nonatomic) OOContentMetadata *contentMetadata;
@property (nonatomic) OORequestSettings *requestSetting;

@property (weak, nonatomic)   id<OOPulseVideoAd> videoAd;

@end

@implementation PlayerViewController

- (instancetype)init
{
  self = [super init];
  if (self) {
    _skinViewController = [[SkinViewController alloc] initWithNibName:@"SkinViewController" bundle:[NSBundle mainBundle]];
    _skinViewController.delegate = self;
    _pauseAdViewController = [[PauseAdViewController alloc] initWithNibName:@"PauseAdViewController" bundle:[NSBundle mainBundle]];
    _pauseAdViewController.delegate = self;
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

  // Get notified when a AVPlayerItem finished playback
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onPlaybackFinished:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:nil];
}

- (void)initializeView
{
  // Create a AVPlayerViewController that will be responsible for displaying video
  self.skinViewController.player = self.player;
  [self addChildViewController:self.skinViewController];
  [self.view addSubview:self.skinViewController.view];
  [self.skinViewController.view setFrame:self.view.frame];
  
  [self addChildViewController:self.pauseAdViewController];
  [self.view addSubview:self.pauseAdViewController.view];
  [self.pauseAdViewController.view setFrame:self.view.frame];
  
  // Create a skip view controller
  self.skipViewController = [[SkipViewController alloc] initWithNibName:@"SkipViewController" bundle:[NSBundle mainBundle]];
  self.skipViewController.delegate = self;
  [self addChildViewController:self.skipViewController];
  [self.view addSubview:self.skipViewController.view];
  [self.skipViewController.view setFrame:CGRectInset(self.view.frame, 0, 20)];
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

- (void)playContentWithURL:(NSURL *)url contentMetadata:(OOContentMetadata *)contentMetadata requestSettings:(OORequestSettings *)requestSettings videoItem:(VideoItem *)videoItem
{
  [self.player replaceCurrentItemWithPlayerItem:nil];
  [self.player cancelPendingPrerolls];
  self.videoAd = nil;
  self.adAsset = nil;
  self.contentItem = nil;
  self.videoItem = videoItem;
  self.contentAsset = [AVAsset assetWithURL:url];
  [self.contentAsset preload];
  self.isSessionExtensionRequested = NO;
  self.contentMetadata = [[OOContentMetadata alloc] init];
  self.contentMetadata = contentMetadata;
  self.requestSetting = [[OORequestSettings alloc] init];
  self.requestSetting = requestSettings;
  
  [self setIsLoading:YES];
  self.session = [OOPulse sessionWithContentMetadata:contentMetadata requestSettings:requestSettings];
  [self.session startSessionWithDelegate:self];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Video playback support

- (void)play:(AVPlayerItem *)item
{
  [self.player replaceCurrentItemWithPlayerItem:item];
  [self.player play];
}

// Returns YES if asset is the same one as in the current player item.
- (BOOL)isAssetActive:(AVAsset *)asset
{
  // For the asset to be active it must be non-null, and equal to the
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
    [self.videoAd adPaused];
  }
}

- (void)applicationWillEnterForeground
{
  if (playbackRateBeforeBackground > 0 && [self isAssetPaused:self.adAsset]) {
    [self.videoAd adResumed];
  }
  [self.player setRate:playbackRateBeforeBackground];
}

- (void)onPlaybackFinished:(NSNotification *)notification
{
  // Execute on main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([notification.object asset] == self.adAsset) {
      self.adAsset = nil;
      [self.videoAd adFinished];
    }
    else if ([notification.object asset] == self.contentAsset) {
      [self.session contentFinished];
    }
  });
}

- (void)playbackPositionChanged:(NSTimeInterval)position
{
  // Ensure that we are currently playing either the content or an ad.
  // We need to check this because sometimes the periodic time observer callbacks
  // are already in the dispatch queue when we change the video player state.
  if ([self isAssetPlaying:self.adAsset]
      || [self isAssetPlaying:self.contentAsset]) {

    if (self.state == PlayerStateLoading) {
      if (self.adAsset) {
        [self.skipViewController updateWithSkippable:[self.videoAd isSkippable]
                                          skipOffset:[self.videoAd skipOffset]
                                          adPosition:0];
       [self.videoAd adStarted:0.5f];
      }
      else
        [self.session contentStarted];
      [self setIsLoading:NO];
    }
    else {
      if (self.adAsset) {
        [self.skipViewController updateWithSkippable:[self.videoAd isSkippable]
                                          skipOffset:[self.videoAd skipOffset]
                                          adPosition:position];
        [self.videoAd adPositionChanged:position];
      }
      else
      {
        [self.session contentPositionChanged:position];
        if ([self.videoItem.title  isEqual: @"Session extension"] && !self.isSessionExtensionRequested)
        {
          if (fabs(position - 10) < 0.1)
          {
            self.isSessionExtensionRequested = YES;
           [self requestSessionExtension];
          }
        }
      }
    }
  }
}

#pragma mark - OOPulseSessionDelegate

- (void)startContentPlayback
{
  NSLog(@"OOPulseSessionDelegate.startContentPlayback");

  [self.player pause];
  [self setIsLoading:YES];

  [self.skinViewController showControls];
  self.skinViewController.requiresLinearPlayback = NO;
  self.adAsset = nil;
  self.skipViewController.view.hidden = YES;

    if (self.contentItem){
        [self.skinViewController changeToPauseIcon];
        [self play:self.contentItem];
    }
  else {
    [self.contentAsset preloadWithTimeout:15 success:^(AVAsset *asset) {
      self.contentItem = [AVPlayerItem playerItemWithAsset:asset];
      [self.skinViewController changeToPauseIcon];
      [self play:self.contentItem];
    } failure:^(OOPulseAdError error) {
      [self dismissViewControllerAnimated:YES completion:nil];
    }];
  }
}

- (void)startAdBreak:(id<OOPulseAdBreak>)adBreak
{
  NSLog(@"OOPulseSessionDelegate.startAdBreak");

  [self.player pause];
  [self.player replaceCurrentItemWithPlayerItem:nil];
  [self.skinViewController showControlsAlways];
  self.skinViewController.requiresLinearPlayback = YES;
  [self setIsLoading:YES];
}

- (void)startAdPlaybackWithAd:(id<OOPulseVideoAd>)ad timeout:(NSTimeInterval)timeout
{
  NSLog(@"OOPulseSessionDelegate.startAdPlaybackWithAd: %@ %d %f", ad, [ad isSkippable], [ad skipOffset]);

  // Use the first media file. In a production app the asset selection algorithm
  // should select the ideal media file based on size, bandwidth and format
  // considerations.
  self.adAsset = [AVAsset assetWithURL:[ad.mediaFiles.firstObject URL]];

  [self.player pause];
  [self setIsLoading:YES];
  [INOmidAdSession createOmidAdSessionWithView:self.view pulseVideoAd:ad contentUrl:@"invidi.pulseplayer.com"];
  [self.adAsset preloadWithTimeout:timeout success:^(AVAsset *asset) {
    self.videoAd = ad;
    [self.skinViewController changeToPauseIcon];
    [self play:[AVPlayerItem playerItemWithAsset:asset]];
  } failure:^(OOPulseAdError error) {
    self.adAsset = nil;
    [ad adFailedWithError:error];
  }];
}

- (void)preloadNextAdWithAd:(id<OOPulseVideoAd>)ad
{
    NSLog(@"****************** Preload Next Ad now *************************");
}

- (void)showPauseAd:(id<OOPulsePauseAd>)ad
{
  self.pauseAdViewController.ad = ad;
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
  // In debug mode we throw an illegal operation in order to find and
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

- (void)setIsLoading:(BOOL)loading
{
  self.skinViewController.loading = loading;
  self.state = loading ? PlayerStateLoading : PlayerStatePlaying;
}

- (void)showClickthroughForAd:(id<OOPulseAd>)ad
{
  if ([ad clickthroughURL]) {
    [ad adClickThroughTriggered];
    [[UIApplication sharedApplication] openURL:[ad clickthroughURL]];
  }
}

#pragma mark - SkinViewControllerDelegate

- (void)userTappedVideo
{
  // If we have an ad asset and it is playing, then trigger clickthrough
  if ([self isAssetPlaying:self.adAsset]) {
    [self showClickthroughForAd:self.videoAd];
  } else {
    [self.skinViewController toggleControls];
  }
}

- (void)userPausedVideo
{
  if ([self isAssetActive:self.contentAsset]) {
    if (self.state == PlayerStatePlaying) {
      NSLog(@"Content paused");
      [self.session contentPaused];
    }
  } else if ([self isAssetActive:self.adAsset]) {
      if (self.state == PlayerStatePlaying) {
        NSLog(@"Ad paused");
        [self.videoAd adPaused];
      }
    }
}

- (void)userResumedVideo
{
  if ([self isAssetActive:self.contentAsset]) {
    if (self.state == PlayerStatePlaying) {
      self.pauseAdViewController.ad = nil;
      NSLog(@"Content resumed");
      [self.session contentStarted];
    }
  } else if ([self isAssetActive:self.adAsset]) {
      if (self.state == PlayerStatePlaying) {
        self.pauseAdViewController.ad = nil;
        NSLog(@"Ad resumed");
        [self.videoAd adResumed];
      }
    }
}

- (void)playerStateChanged:(OOPlayerState)playerState
{
   [self.videoAd playerStateChanged:playerState];
}

#pragma mark - PauseAdViewControllerDelegate

- (void)adTapped:(id<OOPulseAd>)ad
{
  [self showClickthroughForAd:ad];
}

#pragma mark - SkipViewControllerDelegate

- (void)skipButtonWasPressed
{
  [self.videoAd adSkipped];
}

#pragma mark - Helper methods
- (void) requestSessionExtension
{
  NSLog(@"Request a session extension for two midrolls at 20th second.");
  self.contentMetadata.tags = @[@"standard-midrolls"];
  self.requestSetting.linearPlaybackPositions = @[@20];
  self.requestSetting.insertionPointFilter = OOInsertionPointTypePlaybackPosition;

  [self.session extendSessionWithContentMetadata:self.contentMetadata requestSettings:self.requestSetting success:^{
    NSLog(@"Session was successfully extended. There are now midroll ads at 20th second.");
  }];
}

@end
