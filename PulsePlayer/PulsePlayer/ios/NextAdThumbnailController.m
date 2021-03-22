//
//  NextAdThumbnailController.m
//  PulsePlayer
//
//  Created by Sravani Kancharla on 2021-03-09.
//  Copyright © 2021 Ooyala. All rights reserved.
//

#import "NextAdThumbnailController.h"
#import <AVFoundation/AVFoundation.h>
@interface NextAdThumbnailController ()

@property (strong, nonatomic) IBOutlet UIImageView *nextAdImageView;

@end

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
    self.view.hidden = YES;
}

- (void)getNextAdThumbnail: (NSURL *)url
{
    self.view.hidden = NO;
    AVAsset* asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = CMTimeMake(1, 1);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    _nextAdImageView.image = [UIImage imageWithCGImage:imageRef];

}

@end
