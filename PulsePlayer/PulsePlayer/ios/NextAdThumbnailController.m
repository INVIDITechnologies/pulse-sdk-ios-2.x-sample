//
//  NextAdThumbnailController.m
//  PulsePlayer
//
//  Created by Sravani Kancharla on 2021-03-09.
//  Copyright © 2021 Ooyala. All rights reserved.
//

#import "NextAdThumbnailController.h"
#import <AVfoundation/AVFoundation.h>

@implementation NextAdThumbnailController

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)getNextAdThumbnailImage: (NSURL *)url
{
    self.view.hidden = NO;
    _NextAdImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 80, 60)];
    AVAsset* asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = CMTimeMake(1, 1);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    _NextAdImageView.image = [UIImage imageWithCGImage:imageRef];
    
    CGRect NextAdImageFrame = self.NextAdImageView.frame;
    
    NextAdImageFrame.size.width = NextAdImageFrame.size.width - self.view.frame.origin.x;
    NextAdImageFrame.origin.x = self.view.frame.size.width - NextAdImageFrame.size.width;
    
    NextAdImageFrame.origin.y = self.view.frame.size.height - 450;

    self.NextAdImageView.frame = NextAdImageFrame;
    [self.view addSubview:_NextAdImageView];
  
}

@end
