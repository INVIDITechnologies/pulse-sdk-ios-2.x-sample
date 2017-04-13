//
//  AVAsset+Preloading.h
//  PulsePlayer
//
//  Created by Jacques du Toit on 21/10/15.
//  Copyright © 2015 Ooyala. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#if TARGET_OS_IOS
#import <Pulse/Pulse.h>
#elif TARGET_OS_TV
#import <Pulse_tvOS/Pulse.h>
#endif

/**
 *  This category provides functionality for preloading an AVAsset,
 *  with error reporting. The asset should be ready to play immediately
 *  after preloading.
 */
@interface AVAsset (Preloading)

/**
 *  Preload this asset.
 *
 *  @param timeout   Seconds to allow it to load before failing. (Use 0 for no timeout).
 *  @param onSuccess Block to call on success
 *  @param onFailure Block to call on failure
 */
- (void)preloadWithTimeout:(NSTimeInterval)timeout
                   success:(void(^)(AVAsset *asset))onSuccess
                   failure:(void(^)(OOPulseAdError error))onFailure;

/**
 *  Preload this asset.
 */
- (void)preload;

@end
