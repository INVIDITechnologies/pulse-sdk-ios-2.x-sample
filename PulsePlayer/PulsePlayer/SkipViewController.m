//
//  SkipViewController.m
//  PulsePlayer
//
//  Created by Jacques du Toit on 09/03/16.
//  Copyright © 2016 Ooyala. All rights reserved.
//

#import "SkipViewController.h"

@interface SkipViewController ()

@property (strong, nonatomic) NSString *skipLabelText;

@property (weak, nonatomic) IBOutlet UIView *background;
@property (weak, nonatomic) IBOutlet UILabel *skipLabel;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;


@end

@implementation SkipViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self.skipButton addTarget:self action:@selector(skipButtonWasPressed) forControlEvents:UIControlEventTouchUpInside|UIControlEventPrimaryActionTriggered];
  self.skipLabelText = self.skipLabel.text;
  self.view.hidden = YES;
}

- (void)skipButtonWasPressed
{
  [self.delegate skipButtonWasPressed];
}

- (UIView *)preferredFocusedView
{
  return self.skipButton.hidden ? nil : self.skipButton;
}

- (void)updateWithSkippable:(BOOL)isSkippable skipOffset:(NSTimeInterval)offset adPosition:(NSTimeInterval)position
{
  if (isSkippable) {
    BOOL cannotSkipYet = position < offset;
    if (cannotSkipYet) {
      self.skipLabel.text = [self.skipLabelText stringByReplacingOccurrencesOfString:@"$S" withString:[@(ceil(offset-position)) stringValue]];
    }
    self.skipButton.hidden = cannotSkipYet;
    self.skipLabel.hidden = !cannotSkipYet;
    
    // Update the background width
    UIView *view = cannotSkipYet ? self.skipLabel : self.skipButton;
    CGRect frame = self.background.frame;
    frame.size.width = frame.size.width - view.frame.origin.x;
    frame.origin.x = self.view.frame.size.width - frame.size.width;
    self.background.frame = frame;
    
#if TARGET_OS_TV
    [self setNeedsFocusUpdate];
#endif
  }
  
  self.view.hidden = !isSkippable;
}


@end
