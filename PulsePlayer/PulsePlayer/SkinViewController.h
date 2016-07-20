//
//  SkinViewController
//  PulsePlayer
//
//  Created by Steve on 22/06/16.
//  Copyright © 2016 Ooyala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

@protocol SkinViewControllerDelegate <NSObject>

- (void)playbackPositionChanged:(NSTimeInterval)position;
- (void)userTappedVideo;
- (void)userPausedVideo;
- (void)userResumedVideo;

@end

@interface SkinViewController : UIViewController

@property (strong, nonatomic) AVPlayer* player;

@property(nonatomic) BOOL requiresLinearPlayback;
@property(nonatomic, getter=isLoading) BOOL loading;

- (void)toggleControls;
- (void)showControls;
- (void)hideControls;

@property (weak, nonatomic) IBOutlet UIView *contentOverlayView;

@property (weak, nonatomic) id<SkinViewControllerDelegate> delegate;
@end