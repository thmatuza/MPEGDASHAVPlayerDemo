//
//  ViewController.swift
//  MPEGDASHAVPlayerDemo
//
//  Created by Tomohiro Matsuzawa on 2019/11/28.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    // Asset keys
    let playableKey = "playable"

    private var seekToZeroBeforePlay = false
    private var delegate: CustomPlaylistDelegate?
    private var observeStatus: NSKeyValueObservation?
    private var observeRate: NSKeyValueObservation?
    private var observeCurrentItem: NSKeyValueObservation?

    @IBOutlet private var playView: PlayerView!
    @IBOutlet private var pauseButton: UIBarButtonItem!
    @IBOutlet private var playButton: UIBarButtonItem!
    @IBOutlet private var toolbar: UIToolbar!

    private var _url: URL?
    private var url: URL? {
        get {
            return _url
        }
        set {
            guard let newValue = newValue else {
                return
            }
            if _url != newValue {
                _url = newValue

                /*
                 Create an asset for inspection of a resource referenced by a given URL.
                 Load the values for the asset keys  "playable".
                 */
                let asset = AVURLAsset(url: newValue, options: nil)
                configDelegates(asset)

                let requestedKeys = [playableKey]

                // Tells the asset to load the values of any of the specified keys that are not already loaded.
                asset.loadValuesAsynchronously(forKeys: requestedKeys, completionHandler: {
                    DispatchQueue.main.async {
                        self.prepare(toPlay: asset, withKeys: requestedKeys)
                    }
                })
            }
        }
    }

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?

    private func setupToolbar() {
        toolbar.items = [playButton]
        syncPlayPauseButtons()
    }

    private func initializeView() {
        let urls = [
            "https://dash.akamaized.net/dash264/TestCasesHD/1b/qualcomm/1/MultiRate.mpd",
            "https://dash.akamaized.net/dash264/TestCasesHD/1b/qualcomm/2/MultiRate.mpd",
            "https://dash.akamaized.net/dash264/TestCasesHD/2b/qualcomm/1/MultiResMPEG2.mpd",
            "https://dash.akamaized.net/dash264/TestCasesHD/2b/qualcomm/2/MultiRes.mpd",
            "https://dash.akamaized.net/dash264/TestCases/1b/qualcomm/1/MultiRatePatched.mpd",
            "https://dash.akamaized.net/dash264/TestCases/1b/qualcomm/2/MultiRate.mpd",
            "https://dash.akamaized.net/dash264/TestCases/2b/qualcomm/1/MultiResMPEG2.mpd",
            "https://dash.akamaized.net/dash264/TestCases/2b/qualcomm/2/MultiRes.mpd",
            "https://dash.akamaized.net/dash264/TestCases/9b/qualcomm/1/MultiRate.mpd",
            "https://dash.akamaized.net/dash264/TestCases/9b/qualcomm/2/MultiRate.mpd",
        ]
        if let url = URL(string: toCustomUrl(urls[0])) {
            self.url = url
        }
    }

    override func viewDidLoad() {
        setupToolbar()
        initializeView()
        super.viewDidLoad()
    }

    /*!
     *  Create the asset to play (using the given URL).
     *  Configure the asset properties and callbacks when the asset is ready.
     */
    /*!
     *  Create and setup the custom delegae instance.
     */
    private func configDelegates(_ asset: AVURLAsset) {
        // Setup the delegate for custom URL.
        delegate = CustomPlaylistDelegate()
        let resourceLoader = asset.resourceLoader
        resourceLoader.setDelegate(delegate, queue: DispatchQueue(label: "AVARLDelegateDemo loader"))
    }

    /*!
     *  Gets called when the play button is pressed.
     *  Start the playback of the asset and show the pause button.
     */
    @IBAction func issuePlay(_: Any) {
        if seekToZeroBeforePlay {
            seekToZeroBeforePlay = false
            player?.seek(to: .zero)
        }

        player?.play()
        showPauseButton()
    }

    /*!
     *  Gets called when the pause button is pressed.
     *  Stop the play and show the play button.
     */
    @IBAction func issuePause(_: Any) {
        player?.pause()
        showPlayButton()
    }
}

/*!
 *  Interface for the play control buttons.
 *  Play
 *  Pause
 */
private extension ViewController {
    func showButton(_ button: UIBarButtonItem) {
        var toolbarItems: [UIBarButtonItem]?
        if let items = toolbar.items {
            toolbarItems = items
        }
        toolbarItems?[0] = button
        toolbar.items = toolbarItems
    }

    func showPlayButton() {
        showButton(playButton)
    }

    func showPauseButton() {
        showButton(pauseButton)
    }

    func syncPlayPauseButtons() {
        // If we are playing, show the pause button otherwise show the play button
        if isPlaying() {
            showPauseButton()
        } else {
            showPlayButton()
        }
    }

    func enablePlayerButtons() {
        playButton.isEnabled = true
        pauseButton.isEnabled = true
    }

    func disablePlayerButtons() {
        playButton.isEnabled = false
        pauseButton.isEnabled = false
    }
}

/*!
 *  Interface for the AVPlayer
 *  - observe the properties
 *  - initialize the play
 *  - play status
 *  - play failed
 *  - play ended
 */
private extension ViewController {
    /*!
     *  Invoked at the completion of the loading of the values for all keys on the asset that we require.
     *  Checks whether loading was successfull and whether the asset is playable.
     *  If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
     */
    func prepare(toPlay asset: AVURLAsset, withKeys requestedKeys: [AnyHashable]) {
        // Make sure that the value of each key has loaded successfully.
        for thisKey in requestedKeys {
            guard let thisKey = thisKey as? String else {
                continue
            }
            var error: NSError?
            let keyStatus = asset.statusOfValue(forKey: thisKey, error: &error)
            if keyStatus == .failed {
                assetFailedToPrepare(forPlayback: error)
                return
            }
            // If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation.
        }

        // Use the AVAsset playable property to detect whether the asset can be played.
        if !asset.isPlayable {
            // Generate an error describing the failure.
            let localizedDescription =
                NSLocalizedString("Item cannot be played", comment: "Item cannot be played description")
            let localizedFailureReason = NSLocalizedString("The contents of the resource at the specified URL are not playable.", comment: "Item cannot be played failure reason")
            let errorDict = [
                NSLocalizedDescriptionKey: localizedDescription,
                NSLocalizedFailureReasonErrorKey: localizedFailureReason,
            ]
            let assetCannotBePlayedError = NSError(domain: Bundle.main.bundleIdentifier ?? "", code: 0, userInfo: errorDict)

            // Display the error to the user.
            assetFailedToPrepare(forPlayback: assetCannotBePlayedError)

            return
        }

        // At this point we're ready to set up for playback of the asset.

        // Stop observing our prior AVPlayerItem, if we have one.
        if playerItem != nil {
            // Remove existing player item key value observers and notifications.
            observeStatus?.invalidate()
            observeStatus = nil

            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }

        // Create a new instance of AVPlayerItem from the now successfully loaded AVAsset.
        playerItem = AVPlayerItem(asset: asset)

        // Observe the player item "status" key to determine when it is ready to play.
        observeStatus = playerItem?.observe(\.status, options: [.initial, .new], changeHandler: { item, change in
            self.syncPlayPauseButtons()

            // workaround for https://bugs.swift.org/browse/SR-11617
            let status = change.newValue ?? item.status

            switch status {
            /* Indicates that the status of the player is not yet known because
             it has not tried to load new media resources for playback */
            case .unknown:
                self.disablePlayerButtons()
            case .readyToPlay:
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */

                self.enablePlayerButtons()
            case .failed:
                self.assetFailedToPrepare(forPlayback: item.error)
            @unknown default:
                break
            }
        })

        /* When the player item has played to its end time we'll toggle
         the movie controller Pause button to be the Play button */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        seekToZeroBeforePlay = false

        // Create new player, if we don't already have one.
        if player == nil {
            // Get a new AVPlayer initialized to play the specified player item.
            player = AVPlayer(playerItem: playerItem)

            /* Observe the AVPlayer "currentItem" property to find out when any
             AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
             occur.*/
            observeCurrentItem = player?.observe(\.currentItem, options: [.initial, .new], changeHandler: { player, change in
                let newPlayerItem = change.newValue

                // Is the new player item null?
                if newPlayerItem == nil {
                    self.disablePlayerButtons()
                } else {
                    // Set the AVPlayer for which the player layer displays visual output.
                    self.playView.player = player

                    /* Specifies that the player should preserve the video’s aspect ratio and
                     fit the video within the layer’s bounds. */
                    self.playView.setVideoFillMode(.resizeAspect)

                    self.syncPlayPauseButtons()
                }
            })

            // Observe the AVPlayer "rate" property to update the scrubber control.
            observeRate = player?.observe(\.rate, options: [.initial, .new], changeHandler: { _, _ in
                self.syncPlayPauseButtons()
            })
        }

        // Make our new AVPlayerItem the AVPlayer's current item.
        if player?.currentItem != playerItem {
            /* Replace the player item with a new player item. The item replacement occurs
             asynchronously; observe the currentItem property to find out when the
             replacement will/did occur*/
            player?.replaceCurrentItem(with: playerItem)

            syncPlayPauseButtons()
        }
    }

    func isPlaying() -> Bool {
        guard let player = player else {
            return false
        }
        return player.rate != 0.0
    }

    /*!
     *  Called when an asset fails to prepare for playback for any of
     *  the following reasons:
     *
     *  1) values of asset keys did not load successfully,
     *  2) the asset keys did load successfully, but the asset is not
     *     playable
     *  3) the item did not become ready to play.
     */
    func assetFailedToPrepare(forPlayback error: Error?) {
        disablePlayerButtons()
        let title = error?.localizedDescription ?? ""
        let message = (error as NSError?)?.localizedFailureReason ?? ""

        // Display the error.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // We add buttons to the alert controller by creating UIAlertActions:
        let actionOk = UIAlertAction(title: "OK",
                                     style: .default,
                                     handler: nil) // You can use a block here to handle a press on this button

        alertController.addAction(actionOk)

        present(alertController, animated: true, completion: nil)
    }

    /*!
     *  Called when the player item has played to its end time.
     */
    @objc func playerItemDidReachEnd(_: Notification?) {
        /* After the movie has played to its end time, seek back to time zero
         to play it again. */
        seekToZeroBeforePlay = true
    }
}
