//
//  NextAdThumbnailController.h
//  PulsePlayer
//
//  Created by Sravani Kancharla on 2021-03-09.
//  Copyright © 2021 Ooyala. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol NextAdThumbnailControllerDelegate <NSObject>

NS_ASSUME_NONNULL_BEGIN

@end

@interface NextAdThumbnailController : UIViewController

@property (weak, nonatomic) id<NextAdThumbnailControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIView *NextAdView;
@property (strong, nonatomic) IBOutlet UIImageView *NextAdImageView;


-(void)getNextAdThumbnailImage:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
