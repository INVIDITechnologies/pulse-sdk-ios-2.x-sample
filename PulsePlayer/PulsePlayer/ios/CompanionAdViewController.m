//
//  CompanionAdViewController.m
//  PulsePlayer
//
//  Created by Joao Sampaio on 13/04/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

#import <AVfoundation/AVFoundation.h>
#import "CompanionAdViewController.h"

@interface CompanionAdViewController ()

@property(strong, nonatomic) NSURLSessionTask *task;
@property (weak, nonatomic) IBOutlet UIButton *clickthroughButton;

- (IBAction)adTapped;

@end

@implementation CompanionAdViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.imageView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 80);
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
    self.clickthroughButton.frame = self.imageView.frame;
  }
}

- (void)setImage:(UIImage *)image
{
  NSLog(@"Showing companion ad");
  self.imageView.image = image;
  if (image) {
    [self.ad adDisplayed];
  }
}

- (void)setAd:(id<OOPulseCompanionAd>)ad
{
  _ad = ad;
  if (ad) {
    // Clear out previous pending task if any
    if (self.task) {
      [self.task cancel];
      self.task = nil;
    }
    
    // Start a new download and display task
    __weak CompanionAdViewController *weakSelf = self;
    NSURLSession *session = [NSURLSession sharedSession];
    self.task = [session dataTaskWithURL:[ad resourceURL]
                       completionHandler:^(NSData *data,
                                           NSURLResponse *response,
                                           NSError *error)
                 {
                   UIImage *image = [UIImage imageWithData:data];
                   dispatch_async(dispatch_get_main_queue(), ^{
                     CompanionAdViewController *this = weakSelf;
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

- (void)adTapped {
  [self.delegate adTapped:self.ad];
}

@end
