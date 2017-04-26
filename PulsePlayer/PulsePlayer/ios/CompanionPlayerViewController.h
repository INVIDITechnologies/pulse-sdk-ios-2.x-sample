//
//  CompanionPlayerViewController.h
//  PulsePlayer
//
//  Created by Joao Sampaio on 10/04/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

#if TARGET_OS_IOS
#import <Pulse/Pulse.h>
#else
#import <Pulse_tvOS/Pulse.h>
#endif
#import "VideoItem.h"
#import <UIKit/UIKit.h>

@class CompanionPlayerViewController;

@interface CompanionPlayerViewController : UIViewController

/// Play the content along with ads coming from a Pulse session requested with
/// the given content metadata and request settings.
- (void)playContentWithURL:(NSURL *)url contentMetadata:(VPContentMetadata *)metadata requestSettings:(VPRequestSettings *)requestSettings videoItem:(VideoItem *)videoItem;

@end
