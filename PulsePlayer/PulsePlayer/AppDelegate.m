//
//  AppDelegate.m
//  PulsePlayer
//
//  Created by Jacques du Toit on 12/10/15.
//  Copyright © 2015 Ooyala. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#if TARGET_OS_IOS
#import <Pulse/Pulse.h>
#elif TARGET_OS_TV
#import <Pulse_tvOS/Pulse.h>
#endif

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Initialize the Pulse SDK.
  // Host:
  //     Your Pulse account host
  // Device Container:
  //     Device container in Ooyala Pulse is used for targeting and
  //     reporting purposes. This device container attribute is only used
  //     if you want to override the Pulse device detection algorithm on the
  //     Pulse ad server. This should only be set if normal device detection
  //     does not work and only after consulting Ooyala personnel. An incorrect
  //     device container value can result in no ads being served or incorrect
  //     ad delivery and reports.
  // Persistent Id:
  //     The persistent identifier is used to identify the end user and is the
  //     basis for frequency capping, uniqueness, DMP targeting information and
  //     more. Use Apple's advertising identifier (IDFA), or your own unique
  //     user identifier here.
  // Refer to:
  //     http://support.ooyala.com/developers/ad-documentation/oadtech/ad_serving/dg/integration_sdk_parameter.html
  [OOPulse setPulseHost:@"https://pulse-demo.videoplaza.tv" deviceContainer:nil persistentId:[[NSUUID UUID] UUIDString]];

  // Set audio session category:
  //   Playback only. Plays audio even with the screen locked and with the
  //   Ring/Silent switch set to silent. Use this category for an app whose audio
  //   playback is of primary importance.
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
