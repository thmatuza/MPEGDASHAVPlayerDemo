# MPEGDASHAVPlayerDemo
This demo project is inspired by [DASH-to-HLS-Playback](https://github.com/huzhlei/DASH-to-HLS-Playback) project.
It converts [DASH](https://en.wikipedia.org/wiki/Dynamic_Adaptive_Streaming_over_HTTP)'s MPD manifests to [HLS](https://en.wikipedia.org/wiki/HTTP_Live_Streaming)'s M3U8 manifests. It works by extracting information from MPD files, creating M3U8 master playlist and media playlists, finally plays out with [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer).

It is written with Swift.

## Getting Worked
Run `pod install` and open the `xcworkspace` file that is created.

## Technical Overview
It is using [AVAssetResourceLoaderDelegate](https://developer.apple.com/documentation/avfoundation/avassetresourceloaderdelegate) to modify the behavior when AVPlayer load the HLS playlists.
Apple sample code is available [here](https://developer.apple.com/library/archive/samplecode/sc1791/Introduction/Intro.html#//apple_ref/doc/uid/DTS40014357).
I also created the [demo project](https://github.com/thmatuza/custom-playlist-demo) that simply manipulates the master and media playlists AVPlayer loading.

#### Notes
+ If loading MPD from URL, media segments must locate at the same address of the given MPD file.
+ It only supports MPD file with one period. If several periods in the MPD, it only works on the first period.
+ It only supports VOD. (I will work on Live soon!)
