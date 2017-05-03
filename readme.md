# Ooyala Pulse SDK 2.x sample integration for iOS and tvOS

This project demonstrates a simple video player that requests and shows ads using the Ooyala Pulse SDK.

This project is a sample intended **only** to give a brief introduction to the Pulse SDK and help developers get started with their iOS integration.

This is absolutely **not** intended to be used in production or to outline best practices, but rather a simplified way of developing your integration.


## Building

1. After cloning the project, download the Ooyala Ad Products iOS SDKs [here](http://support.ooyala.com/resources/mobile-and-client-sdks).
2. Copy the [required](Pulse/readme.md) framework files into the Pulse folder of the project.
3. Open the project file in XCode.
4. Select the ```PulsePlayer``` scheme  for iOS, or the ```PulsePlayer (TVOS)``` scheme for tvOS.
5. Build the project.


## Project structure

The Pulse SDK is initialized in the [app delegate](PulsePlayer/PulsePlayer/AppDelegate.m).

A [VideoLibraryViewController](PulsePlayer/PulsePlayer/VideoLibraryViewController.m) shows a list of available videos, along with some [metadata](PulsePlayer/PulsePlayer/VideoItem.h). When a video is selected, it is opened in a [PlayerViewController](PulsePlayer/PulsePlayer/PlayerViewController.h) (specialized for  [iOS](PulsePlayer/PulsePlayer/ios/PlayerViewController.m) and [tvOS](PulsePlayer/PulsePlayer/tvos/PlayerViewController.m)).

The PlayerViewController creates a [OOPulseSession](http://pulse-sdks.ooyala.com/ios_2/latest/Protocols/OOPulseSession.html) using the [OOPulse](http://pulse-sdks.ooyala.com/ios_2/latest/Classes/OOPulse.html) class. This OOPulseSession informs the PlayerViewController through the [OOPulseSessionDelegate](http://pulse-sdks.ooyala.com/ios_2/latest/Protocols/OOPulseSessionDelegate.html) protocol when it is time to play ads or the content.

A helper category [AVAsset+Preloading](PulsePlayer/PulsePlayer/AVAsset+Preloading.h) is used to preload media files in another thread and reports back if an error occurred.

All tracking of ad impressions and inventory is automatically handled.


## Demo Pulse account

This integration sample uses the following Pulse account:
```
https://pulse-demo.videoplaza.tv
```

This account is configured with a set of ad campaigns to help you test your Ooyala Pulse integration. Refer to the [content library](PulsePlayer/PulsePlayer/library.json) used in this sample for useful tags and categories.


## Useful information

- [The Ooyala Pulse SDK documentation](http://pulse-sdks.ooyala.com/ios_2/latest/index.html)
- [Ooyala Ad Products SDK Parameter Reference](http://help.ooyala.com/video-advertising/oadtech/ad_serving/dg/integration_sdk_parameter.html)
