//
//  PlayerViewController.h
//  PulsePlayer
//
//  Created by Jacques du Toit on 12/10/15.
//  Copyright © 2015 Ooyala. All rights reserved.
//

#import <Pulse/Pulse.h>

@class PlayerViewController;


// Delegate methods for PlayerViewController
@protocol PlayerViewControllerDelegate <NSObject>

/// iOS only. Called when picture in picture mode has completed, and the full screen
/// video playback controller has to be restored.
- (void)playerViewController:(PlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler;

@end


/// A View controller for video and ad playback
@interface PlayerViewController : UIViewController

/// Play the content along with ads coming from a Pulse session requested with
/// the given content metadata and request settings.
- (void)playContentWithURL:(NSURL *)url contentMetadata:(VPContentMetadata *)metadata requestSettings:(VPRequestSettings *)requestSettings;

/// The delegate that will receive messages from this player view controller.
@property (strong, nonatomic) id<PlayerViewControllerDelegate> delegate;

@end
