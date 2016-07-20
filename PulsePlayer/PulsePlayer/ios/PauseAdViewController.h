//
//  PauseAdViewController.h
//  PulsePlayer
//
//  Created by Jacques du Toit on 29/06/16.
//  Copyright © 2016 Ooyala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Pulse/Pulse.h>

@protocol PauseAdViewControllerDelegate <NSObject>

- (void)adTapped:(id<OOPulseAd>)ad;

@end

@interface PauseAdViewController : UIViewController

@property (strong, nonatomic) id<OOPulsePauseAd> ad;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)closeButtonPressed;

@property (weak, nonatomic) id <PauseAdViewControllerDelegate> delegate;

@end
