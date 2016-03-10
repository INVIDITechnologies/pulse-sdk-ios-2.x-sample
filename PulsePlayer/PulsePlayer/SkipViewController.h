//
//  SkipViewController.h
//  PulsePlayer
//
//  Created by Jacques du Toit on 09/03/16.
//  Copyright © 2016 Ooyala. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SkipViewControllerDelegate <NSObject>

- (void)skipButtonWasPressed;

@end

@interface SkipViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *background;
@property (weak, nonatomic) IBOutlet UILabel *skipLabel;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@property (weak, nonatomic) id<SkipViewControllerDelegate> delegate;

- (void)updateWithSkippable:(BOOL)isSkippable skipOffset:(NSTimeInterval)offset adPosition:(NSTimeInterval)position;

@end
