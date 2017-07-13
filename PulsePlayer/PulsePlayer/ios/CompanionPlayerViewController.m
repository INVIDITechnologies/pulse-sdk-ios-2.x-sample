//
//  CompanionPlayerViewController.m
//  PulsePlayer
//
//  Created by Joao Sampaio on 10/04/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

#import "CompanionPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "AVAsset+Preloading.h"
#import "SkipViewController.h"
#import "SkinViewController.h"
#import "PauseAdViewController.h"
#import "CompanionAdViewController.h"
#import "VideoItemCell.h"

typedef enum : NSUInteger {
  PlayerStateIdle = 0,
  PlayerStateLoading = 1,
  PlayerStatePlaying = 2
} PlayerState;

@interface CompanionPlayerViewController () <OOPulseSessionDelegate, SkipViewControllerDelegate, SkinViewControllerDelegate, PauseAdViewControllerDelegate, CompanionAdViewControllerDelegate> {
  
  // Used to restore the playback rate when returning from background mode
  float playbackRateBeforeBackground;
}

@property (strong, nonatomic) PauseAdViewController *pauseAdViewController;
@property (strong, nonatomic) CompanionAdViewController *topCompanionAdViewController;
@property (strong, nonatomic) CompanionAdViewController *bottomCompanionAdViewController;
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

@implementation CompanionPlayerViewController

- (instancetype)init
{
  self = [super init];
  if (self) {
    _skinViewController = [[SkinViewController alloc] initWithNibName:@"SkinViewController" bundle:[NSBundle mainBundle]];
    _skinViewController.delegate = self;
    _pauseAdViewController = [[PauseAdViewController alloc] initWithNibName:@"PauseAdViewController" bundle:[NSBundle mainBundle]];
    _pauseAdViewController.delegate = self;
    
    // companion banners initialization
    _topCompanionAdViewController = [[CompanionAdViewController alloc] initWithNibName:@"CompanionAdViewController" bundle:[NSBundle mainBundle]];
    _topCompanionAdViewController.delegate = self;
    _bottomCompanionAdViewController = [[CompanionAdViewController alloc] initWithNibName:@"CompanionAdViewController" bundle:[NSBundle mainBundle]];
    _bottomCompanionAdViewController.delegate = self;
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
  // Setting the View Controller menus and behavior
  self.view.backgroundColor = [UIColor whiteColor];
  CGFloat navigationBarHeight = 44.f + [UIApplication sharedApplication].statusBarFrame.size.height;
  CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, navigationBarHeight);
  UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame: frame];
  bar.opaque = YES;
  UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closePlayer)];
  self.navigationItem.rightBarButtonItem = closeButton;
  bar.items = @[self.navigationItem];
  [self.view addSubview: bar];

  // Create the area for the top companion banner
  [self addChildViewController:self.topCompanionAdViewController];
  [self.view addSubview:self.topCompanionAdViewController.view];
  self.topCompanionAdViewController.view.frame = CGRectMake(0, navigationBarHeight + 10, UIScreen.mainScreen.bounds.size.width, 80);

  // Create a AVPlayerViewController that will be responsible for displaying video
  self.skinViewController.player = self.player;
  [self addChildViewController:self.skinViewController];
  [self.view addSubview:self.skinViewController.view];
  double height = self.view.frame.size.width * (9.0/16.0);
  [self.skinViewController.view setFrame:CGRectMake(0, self.topCompanionAdViewController.view.frame.origin.y + self.topCompanionAdViewController.view.frame.size.height + 10, self.view.frame.size.width, height)];
  [self.skinViewController disableCloseButton];
  
  [self addChildViewController:self.pauseAdViewController];
  [self.view addSubview:self.pauseAdViewController.view];
  [self.pauseAdViewController.view setFrame:CGRectMake(0, navigationBarHeight + 10, self.view.frame.size.width, height)];
  
  // Create a skip view controller
  self.skipViewController = [[SkipViewController alloc] initWithNibName:@"SkipViewController" bundle:[NSBundle mainBundle]];
  self.skipViewController.delegate = self;
  [self addChildViewController:self.skipViewController];
  [self.view addSubview:self.skipViewController.view];
  [self.skipViewController.view setFrame:CGRectInset(self.skinViewController.view.frame, 0, 20)];
  
  // Create the area for the bottom companion banner
  [self addChildViewController:self.bottomCompanionAdViewController];
  [self.view addSubview:self.bottomCompanionAdViewController.view];
  self.bottomCompanionAdViewController.view.frame = CGRectMake(0, self.skinViewController.view.frame.origin.y + self.skinViewController.view.frame.size.height + 10, UIScreen.mainScreen.bounds.size.width, 80);
}

- (void)closePlayer
{
  [self dismissViewControllerAnimated:YES completion:nil];
  self.topCompanionAdViewController.ad = nil;
  self.bottomCompanionAdViewController.ad = nil;
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
        [self.videoAd adStarted];
        [self showCompanionAds];
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

- (void)startAdBreak:(id<OOPulseAdBreak>)adBreak
{
  NSLog(@"OOPulseSessionDelegate.startAdBreak");
  
  [self.player pause];
  [self.player replaceCurrentItemWithPlayerItem:nil];
  [self.skinViewController hideControls];
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

  [self.adAsset preloadWithTimeout:timeout success:^(AVAsset *asset) {
    self.videoAd = ad;
    [self play:[AVPlayerItem playerItemWithAsset:asset]];
  } failure:^(OOPulseAdError error) {
    self.adAsset = nil;
    [ad adFailedWithError:error];
  }];
}

- (void)showPauseAd:(id<OOPulsePauseAd>)ad
{
  self.pauseAdViewController.ad = ad;
}

- (void)showCompanionAds
{
  for (int i = 0; i < self.videoAd.companions.count; i++) {
    id<OOPulseCompanionAd> companion = self.videoAd.companions[i];
    
    // placing the Companion banners on their respective spots
    if ([companion.zoneIdentifier isEqualToString:@"companion-top"]) {
      self.topCompanionAdViewController.ad = companion;
    } else if ([companion.zoneIdentifier isEqualToString:@"companion-bottom"]) {
      self.bottomCompanionAdViewController.ad = companion;
    }
  }
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
  }
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

#pragma mark - Maintain the portrait layout

- (BOOL)shouldAutorotate {
  return NO;
}

@end
