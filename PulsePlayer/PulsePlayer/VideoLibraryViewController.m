//
//  VideoLibraryViewController.m
//  PulsePlayer
//
//  Created by Jacques du Toit on 13/10/15.
//  Copyright © 2015 Ooyala. All rights reserved.
//

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#if TARGET_OS_IOS
#import <Pulse/Pulse.h>
#else
#import <Pulse_tvOS/Pulse.h>
#endif

#import "VideoLibraryViewController.h"
#import "VideoItemCell.h"

#import "PlayerViewController.h"
#import "CompanionPlayerViewController.h"

#define VIDEO_CELL_REUSE_ID @"VideoItemCell"

@interface VideoLibraryViewController ()

@property (strong, nonatomic) PlayerViewController *playerViewController;
@property (strong, nonatomic) CompanionPlayerViewController *companionPlayerViewController;

// Our video library is just an array of VideoItem objects
@property (strong, nonatomic) NSArray<VideoItem *> *videos;

@end

@implementation VideoLibraryViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.tableView registerNib:[UINib nibWithNibName:@"VideoItemCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:VIDEO_CELL_REUSE_ID];

  self.playerViewController = [[PlayerViewController alloc] init];

#if !TARGET_OS_TV
  self.companionPlayerViewController = [[CompanionPlayerViewController alloc] init];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Start playing the video item at specified index
- (void)playVideo:(NSIndexPath*)indexPath//(NSInteger)index
{
  NSInteger index = indexPath.row;
  VideoItem *videoItem = self.videos[index];

  // Set the ceontent metadata for the Pulse Ad Session request.
  OOContentMetadata *contentMetadata = [OOContentMetadata new];
  contentMetadata.category = videoItem.category;
  contentMetadata.tags = videoItem.tags;
  contentMetadata.contentForm = OOContentFormLong;
  contentMetadata.duration = videoItem.duration;
  contentMetadata.identifier = videoItem.identifier;
  
  // Set the request settings
  OORequestSettings *requestSettings = [[OORequestSettings alloc] init];
  requestSettings.linearPlaybackPositions = videoItem.midrollPositions;
  // Here we assume a landscape orientation for video playback
  requestSettings.width = (NSInteger)MAX(self.view.frame.size.width, self.view.frame.size.height);
  requestSettings.height = (NSInteger)MIN(self.view.frame.size.width, self.view.frame.size.height);
  // You should probably implement some way of determining the max
  // bitrate of ads to request.
  //requestSettings.maxBitRate = [BandwidthChecker maxBitRate];

  if ([videoItem.identifier isEqualToString:@"demo-companion"]) {
#if !TARGET_OS_TV
    // for this sample app, we are only displaying companion banners on portrait orientation
    if (!UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
      [self presentViewController:self.companionPlayerViewController animated:YES completion:^{
        [self.companionPlayerViewController playContentWithURL:videoItem.videoURL
                                               contentMetadata:contentMetadata
                                               requestSettings:requestSettings
                                                     videoItem:videoItem];
      }];
    } else {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
#endif
  } else {
    [self presentViewController:self.playerViewController animated:YES completion:^{
      [self.playerViewController playContentWithURL:videoItem.videoURL
                                    contentMetadata:contentMetadata
                                    requestSettings:requestSettings
                                          videoItem:videoItem];
    }];
  }
}

#pragma mark - Video libray

// Load video library from library.json into a JSON array.
- (NSArray *)JSONVideoObjects
{
  NSError *jsonError;
  NSString* path  = [[NSBundle mainBundle] pathForResource:@"library" ofType:@"json"];
  NSArray *jsonObjects = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithContentsOfFile:path]
                                                         options:0
                                                           error:&jsonError];
  assert(jsonError == nil);
  return jsonObjects;
}

- (NSArray<VideoItem*> *)videos
{
  if (!_videos) {
    // Parse and add each video in the JSON array to our video library
    NSMutableArray *videos = [NSMutableArray array];
    for (NSDictionary *jsonObject in self.JSONVideoObjects) {
      VideoItem *videoItem = [VideoItem videoItemWithDictionary:jsonObject];

      // Temporary hack to hide pause ad item and Companion ads on tvOS,
      // as its custom view controller has not yet been implemented
  #if TARGET_OS_TV
      if([videoItem.title isEqualToString:@"Pause ad demo"]) {
        continue;
      }
      if ([videoItem.identifier isEqualToString:@"demo-companion"]) {
        continue;
      }
  #endif
      [videos addObject:videoItem];
    }

    _videos = videos;
  }
  return _videos;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return section == 0 ? self.videos.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  VideoItemCell *cell = [tableView dequeueReusableCellWithIdentifier:VIDEO_CELL_REUSE_ID forIndexPath:indexPath];
  
  [cell setVideoItem:self.videos[indexPath.row]];
    
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // The rows are slightly taller in the TVOS sample.
#if TARGET_OS_TV
  return 88;
#else
  return 60;
#endif
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self playVideo:indexPath];
}


#pragma mark - AVPlayerViewControllerDelegate

// This method will only be called on iOS where Picture in Picture mode
// is supported.
- (void)playerViewController:(PlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
  [self presentViewController:playerViewController animated:YES completion:^{
    completionHandler(YES);
  }];
}

@end
