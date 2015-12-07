//
//  AVAsset+Preloading.m
//  PulsePlayer
//
//  Created by Jacques du Toit on 21/10/15.
//  Copyright © 2015 Ooyala. All rights reserved.
//

#import "AVAsset+Preloading.h"

@implementation AVAsset (Preloading)

- (void)preloadWithTimeout:(NSTimeInterval)timeout success:(void(^)(AVAsset *asset))onSuccess failure:(void(^)(OOPulseAdError error))onFailure
{
  if (timeout > 0) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      NSError *error;
      AVKeyValueStatus playableStatus = [self statusOfValueForKey:@"playable" error:&error];
      if (playableStatus == AVKeyValueStatusLoading) {
        // Cancel due to timeout
        [self cancelLoading];
        if (onFailure) {
          onFailure(OOPulseAdErrorTimedOut);
        }
      }
    });
  }
  // Start loading asset, if is not loaded yet
  [self loadValuesAsynchronouslyForKeys:@[@"playable", @"duration"] completionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      NSError *error;
      AVKeyValueStatus playableStatus = [self statusOfValueForKey:@"playable" error:&error];
      switch (playableStatus) {
        case AVKeyValueStatusLoaded:
          if (onSuccess)
            onSuccess(self);
          break;
        case AVKeyValueStatusFailed:
          if (onFailure) {
            if ([error.domain isEqualToString:NSURLErrorDomain])
              onFailure(OOPulseAdErrorRequestFailed);
            else
              onFailure(OOPulseAdErrorCouldNotPlay);
          }
          return;
        default:
          break;
      }
    });
  }];
}

- (void)preload
{
  [self preloadWithTimeout:0 success:nil failure:nil];
}
@end
