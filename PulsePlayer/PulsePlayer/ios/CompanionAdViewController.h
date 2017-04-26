//
//  CompanionAdViewController.h
//  PulsePlayer
//
//  Created by Joao Sampaio on 13/04/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

#import <UIKit/UIKit.h>
#if TARGET_OS_IOS
#import <Pulse/Pulse.h>
#else
#import <Pulse_tvOS/Pulse.h>
#endif

@protocol CompanionAdViewControllerDelegate <NSObject>

- (void)adTapped:(id<OOPulseAd>)ad;

@end

@interface CompanionAdViewController : UIViewController

@property (strong, nonatomic) id<OOPulseCompanionAd> ad;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) id <CompanionAdViewControllerDelegate> delegate;

@end
