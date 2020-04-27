//	The MIT License (MIT)
//
//	Copyright (c) 2017-2020 Eric Conner
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

import Foundation
import AVFoundation

// MARK: Type aliases
#if os(iOS) || os(tvOS)
	import UIKit
	import MediaPlayer
	public typealias Image = UIImage
#elseif os(OSX)
	import AppKit
	public typealias Image = NSImage
#endif

/// Simple and easy way to build streaming radio apps for iOS, tvOS, & macOS
open class SwiftyRadio: NSObject {

//*****************************************************************
// MARK: - SwiftyRadio Variables
//*****************************************************************
	fileprivate var Player: AVPlayer!
	fileprivate var PlayerItem: AVPlayerItem!
	fileprivate var track: Track!
	fileprivate var station: Station!

	fileprivate struct Track {
		var title: String = ""
		var artist: String = ""
		var isPlaying: Bool = false
		var artwork: Image?
	}

	fileprivate struct Station {
		var name: String = ""
		var URL: String = ""
		var description: String = ""
		var artwork: Image?
	}


//*****************************************************************
// MARK: - Initialization Functions
//*****************************************************************
	/// Initial setup for SwiftyRadio. Should be included in AppDelegate.swift under `didFinishLaunchingWithOptions`
	open func setup() {
        #if os(iOS) || os(tvOS)
            if #available(iOS 10.0, tvOS 10.0, *) {
                NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListener(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(audioInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)

                // Set AVFoundation category, required for background audio
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("[SwiftyRadio] Setting category to AVAudioSessionCategoryPlayback failed")
                }

                setupRemote()
            } else {
                // Fall back on earlier versions
            }

    		track = Track()
        #endif
	}

	/// Setup the station, must be called before `Play()`
	/// - parameter name: Name of the station
	/// - parameter URL: The station URL
	/// - parameter description: A short description of the station **(optional)**
	/// - parameter artwork: Image to display as album art **(optional)**
	open func setStation(name: String, URL: String, description: String = "", artwork: Image = Image()) {
		station = Station(name: name, URL: URL, description: description, artwork: artwork)
		track.title = station.description
		track.artist = station.name
		updateLockScreen()
		NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioMetadataUpdated"), object: nil)
	}

	/// Setup the Control Center Remote
	fileprivate func setupRemote() {
		#if os(iOS) || os(tvOS)
			if #available(iOS 7.1, tvOS 9.0, *) {
				let center = MPRemoteCommandCenter.shared()

				center.previousTrackCommand.isEnabled = false
				center.nextTrackCommand.isEnabled = false
				center.seekForwardCommand.isEnabled = false
				center.seekBackwardCommand.isEnabled = false
				center.skipForwardCommand.isEnabled = false
				center.skipBackwardCommand.isEnabled = false
				center.ratingCommand.isEnabled = false
				center.changePlaybackRateCommand.isEnabled = false
				center.likeCommand.isEnabled = false
				center.dislikeCommand.isEnabled = false
				center.bookmarkCommand.isEnabled = false

				if #available(iOS 10.0, tvOS 10.0, *) {
					center.changePlaybackPositionCommand.isEnabled = false
				} else if #available(iOS 9.1, tvOS 9.1, *) {
					center.pauseCommand.isEnabled = false
					center.togglePlayPauseCommand.isEnabled = false
				}

				center.playCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
					self.play()
					return MPRemoteCommandHandlerStatus.success
				}

				center.pauseCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
					self.stop()
					return MPRemoteCommandHandlerStatus.success
				}

				center.stopCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
					self.stop()
					return MPRemoteCommandHandlerStatus.success
				}

				center.togglePlayPauseCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
					self.togglePlayStop()
					return MPRemoteCommandHandlerStatus.success
				}
			}
		#endif
	}


//*****************************************************************
// MARK: - General Functions
//*****************************************************************
	/// Get the current playing track title. Use with notification `SwiftyRadioMetadataUpdated`
	/// - returns: Text string of the track title
	open func trackTitle() -> String {
		return track.title
	}

	/// Get the current playing track artist. Use with notification `SwiftyRadioMetadataUpdated`
	/// - returns: Text string of the track artist
	open func trackArtist() -> String {
		return track.artist
	}

	/// Get the station artwork
	/// - returns: UIImage or NSImage of the station artwork
	open func stationArtwork() -> Image {
		return station.artwork!
	}

	/// Get the track artwork
	/// - returns: UIImage or NSImage of the track artwork
	open func trackArtwork() -> Image {
		return track.artwork!
	}

	/// Get the current playing state
	/// - returns: `true` if SwiftyRadio is playing and `false` if it is not
	open func isPlaying() -> Bool {
		return track.isPlaying
	}

	/// Plays the current set station. Uses notification `SwiftyRadioPlayWasPressed`
	open func play() {
		if station.URL != "" {
			if !isPlaying() {
				PlayerItem = AVPlayerItem(url: URL(string: station.URL)!)
				PlayerItem.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
				PlayerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

				Player = AVPlayer(playerItem: PlayerItem)
				Player.play()

				track.isPlaying = true
				NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioPlayWasPressed"), object: nil)
			} else {
				print("[SwiftyRadio] Station is already playing")
			}
		} else {
			print("[SwiftyRadio] Station has not been setup")
		}
	}

	/// Stops the current set station. Uses notification `SwiftyRadioStopWasPressed`
	open func stop() {
		if isPlaying() {
			Player.pause()
			PlayerItem.removeObserver(self, forKeyPath: "timedMetadata")
			PlayerItem.removeObserver(self, forKeyPath: "status")
			Player = nil
			track.isPlaying = false
			track.title = ""
			track.artist = ""
			track.artwork = nil
			NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioStopWasPressed"), object: nil)
		} else {
			print("[SwiftyRadio] Station is already stopped")
		}
	}

	/// Toggles between `play()` and `stop()`. Uses notifications `SwiftyRadioPlayWasPressed` & `SwiftyRadioStopWasPressed`
	open func togglePlayStop() {
		if isPlaying() {
			stop()
		} else {
			play()
		}
	}

	/// Set the meta data to custom values. Uses notification `SwiftyRadioMetadataUpdated`
	/// - parameter title: Custom meta data title
	/// - parameter artist: Custom meta data artist **(If not provided the Station Name will be used)**
	open func customMetadata(_ title: String, artist: String = "") {
		track.title = title
		track.artist = artist

		if artist == "" {
			track.artist = station.name
		}

		updateLockScreen()
		NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioMetadataUpdated"), object: nil)
	}

	/// Update the lock screen with the now playing information
	fileprivate func updateLockScreen() {
		#if os(iOS) || os(tvOS)
			var songInfo = [:] as [String : Any]

			if NSClassFromString("MPNowPlayingInfoCenter") != nil {
				if(station.artwork != nil || track.artwork != nil) {
					let image: Image = (track.artwork != nil) ? track.artwork! : station.artwork!
					var artwork: MPMediaItemArtwork
					if #available(iOS 10.0, tvOS 10.0, *) {
						artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
							return image
						})
						songInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
					} else {
						artwork = MPMediaItemArtwork(image: image)
					}
					songInfo[MPMediaItemPropertyArtwork] = artwork
				}

				songInfo[MPMediaItemPropertyTitle] = track.title
				songInfo[MPMediaItemPropertyArtist] = track.artist

				MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
			}
		#elseif os(OSX)
			let notification = NSUserNotification()
			notification.title = station.name
			notification.subtitle = track.artist
			notification.informativeText = track.title
			notification.identifier = "com.ericconnerapps.SwiftyRadio"
			if(station.artwork != nil || track.artwork != nil) {
				let image: Image = (track.artwork != nil) ? track.artwork! : station.artwork!
				notification.contentImage = image
			}
			NSUserNotificationCenter.default.removeAllDeliveredNotifications()
			NSUserNotificationCenter.default.deliver(notification)
		#endif
	}

	/// Update the track artwork, used for lock screen and control center
	/// - parameter image: Image to display as track artwork
	open func updateTrackArtwork(_ image: Image) {
		track.artwork = image
		updateLockScreen()
	}

	/// Update the station artwork
	/// - parameter image: Image to display as station artwork
	open func updateStationArtwork(_ image: Image) {
		station.artwork = image
		updateLockScreen()
	}

	/// Removes special characters from a text string
	/// - parameter text: Text to be cleaned
	/// - returns: Cleaned text
	fileprivate func clean(_ text: String) -> String {
		let safeChars : Set<Character> = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890'- []")
		return String(text.filter { safeChars.contains($0) })
	}


//*****************************************************************
// MARK: - Notification Functions
//*****************************************************************
	/// Informs the observing object when the value at the specified key path relative to the observed object has changed
	/// - parameter keyPath: The key path, relative to object, to the value that has changed
	/// - parameter object: The source object of the key path keyPath
	/// - parameter change: A dictionary that describes the changes that have been made to the value of the property at the key path keyPath relative to object. Entries are described in Change Dictionary Keys
	/// - parameter context: The value that was provided when the observer was registered to receive key-value observation notifications
	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		/// Called when the player item status changes
		if keyPath == "status" {
            if PlayerItem.status == AVPlayerItem.Status.failed {
				stop()
				customMetadata("\(station.name) is offline", artist: "Please try again later")
				NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioStationOffline"), object: nil)
			}
		}

		/// Called when new song metadata is available
		if keyPath == "timedMetadata" {
			if(PlayerItem.timedMetadata != nil && PlayerItem.timedMetadata!.count > 0) {
				let metaData = PlayerItem.timedMetadata!.first!.value as! String
				let cleanedMetadata = clean(metaData)

				// Remove junk song code i.e. [4T3]
				var removeSongCode = [String]()
				removeSongCode = cleanedMetadata.components(separatedBy: " [")

				// Separate metadata by " - "
				var metadataParts = [String]()
				metadataParts = removeSongCode[0].components(separatedBy: " - ")

				// Set artist to the station name if it is blank or unknown
				switch metadataParts[0] {
					case "", "Unknown", "unknown":
						track.artist = station.name
					default:
						track.artist = metadataParts[0]
				}

				if metadataParts.count > 0 {
					// Remove artist and join remaining values for song title
					metadataParts.remove(at: 0)
					let combinedTitle = metadataParts.joined(separator: " - ")
					track.title = combinedTitle
				} else {
					// If the song title is missing
					track.title = metadataParts[0]
					track.artist = station.name
				}

				// If the track title is still blank use the station description
				if track.title == "" {
					track.title = station.description
				}

				print("[SwiftyRadio] METADATA - artist: \(track.artist) | title: \(track.title)")

				updateLockScreen()
				NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioMetadataUpdated"), object: nil)
			}
		}
	}

	#if os(iOS) || os(tvOS)
		/// Called when when the current audio routing changes
		@objc fileprivate func audioRouteChangeListener(_ notification: Notification) {
			DispatchQueue.main.async(execute: {
				let audioRouteChangeReason = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt

				// Stop audio when headphones are removed
                if AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue == audioRouteChangeReason {
					if self.isPlaying() {
						self.stop()
					}

					print("[SwiftyRadio] Audio Device was removed")
				}
			})
		}

		/// Called when the current audio is interrupted
		@objc fileprivate func audioInterruption(_ notification: Notification) {
			DispatchQueue.main.async(execute: {
				let audioInterruptionReason = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt

				// Stop audio when a phone call is received
                if AVAudioSession.InterruptionType.began.rawValue == audioInterruptionReason {
					if self.isPlaying() {
						self.stop()
					}

					print("[SwiftyRadio] Interruption Began")
				}

                if AVAudioSession.InterruptionType.ended.rawValue == audioInterruptionReason {
					print("[SwiftyRadio] Interruption Ended")
				}
			})
		}
	#endif
}
