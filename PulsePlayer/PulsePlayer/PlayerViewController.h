//
//  PlayerViewController.h
//  PulsePlayer
//
//  Created by Jacques du Toit on 12/10/15.
//  Copyright © 2015 Ooyala. All rights reserved.
//

#if TARGET_OS_IOS
#import <Pulse/Pulse.h>
#elif TARGET_OS_TV
#import <Pulse_tvOS/Pulse.h>
#endif
#import "VideoItem.h"

@class PlayerViewController;

/// A View controller for video and ad playback
@interface PlayerViewController : UIViewController

/// Play the content along with ads coming from a Pulse session requested with
/// the given content metadata and request settings.
- (void)playContentWithURL:(NSURL *)url contentMetadata:(VPContentMetadata *)metadata requestSettings:(VPRequestSettings *)requestSettings videoItem:(VideoItem *)videoItem;

@end
