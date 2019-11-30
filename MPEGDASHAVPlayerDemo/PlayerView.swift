//
//  PlayerView.swift
//  MPEGDASHAVPlayerDemo
//
//  Created by Tomohiro Matsuzawa on 2019/11/28.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import AVFoundation
import UIKit

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return (layer as? AVPlayerLayer)?.player
        }
        set(player) {
            (layer as? AVPlayerLayer)?.player = player
        }
    }

    /*! Specifies how the video is displayed within a player layer’s bounds.
     (AVLayerVideoGravityResizeAspect is default)
     @param NSString fillMode
     */
    func setVideoFillMode(_ fillMode: AVLayerVideoGravity) {
        let playerLayer = layer as? AVPlayerLayer
        playerLayer?.videoGravity = fillMode
    }

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
