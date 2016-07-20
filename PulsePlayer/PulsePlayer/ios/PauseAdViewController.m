//
//  PauseAdViewController.m
//  PulsePlayer
//
//  Created by Jacques du Toit on 29/06/16.
//  Copyright © 2016 Ooyala. All rights reserved.
//

#import <AVfoundation/AVFoundation.h>
#import "PauseAdViewController.h"

@interface PauseAdViewController ()

@property(strong, nonatomic) NSURLSessionTask *task;
@property (weak, nonatomic) IBOutlet UIButton *clickthroughButton;

- (IBAction)adTapped;

@end

@implementation PauseAdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  [self updateClickThroughExtents];
}

- (void)updateClickThroughExtents
{
  if (self.imageView.image) {
    self.clickthroughButton.frame = AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.imageView.frame);
    self.clickthroughButton.backgroundColor = [UIColor redColor];
  }
}

- (void)setImage:(UIImage *)image
{
  NSLog(@"Showing pause ad");
  self.view.hidden = image == nil;
  self.imageView.image = image;
  if (image) {
    [self updateClickThroughExtents];
    [self.ad adDisplayed];
  }
}

- (void)setAd:(id<OOPulsePauseAd>)ad
{
  _ad = ad;
  if (ad) {
    // Clear out previous pending task if any
    if (self.task) {
      [self.task cancel];
      self.task = nil;
    }
    
    // Start a new download and display task
    __weak PauseAdViewController *weakSelf = self;
    NSURLSession *session = [NSURLSession sharedSession];
    self.task = [session dataTaskWithURL:[ad resourceURL]
                       completionHandler:^(NSData *data,
                                           NSURLResponse *response,
                                           NSError *error)
                 {
                   UIImage *image = [UIImage imageWithData:data];
                   dispatch_async(dispatch_get_main_queue(), ^{
                     PauseAdViewController *this = weakSelf;
                     if (!error) {
                       [this setImage:image];
                       this.task = nil;
                     };
                   });
                 }];
    [self.task resume];
  }
  else {
    [self setImage:nil];
    [self.task cancel];
    self.task = nil;
  }
}


- (IBAction)closeButtonPressed
{
  [self.ad adClosed];
  [self setImage:nil];
}

- (IBAction)adTapped {
  [self.delegate adTapped:self.ad];
}

@end
