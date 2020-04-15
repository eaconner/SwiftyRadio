//
//  SwiftyRadio.swift
//  Swifty Radio
//  Simple and easy way to build streaming radio apps for iOS, tvOS, & macOS
//
//  Version 1.4.2
//  Created by Eric Conner on 7/9/16.
//  Copyright © 2017 Eric Conner Apps. All rights reserved.
//

import Foundation
import AVFoundation

// MARK: Typealiases
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
	fileprivate var stationInfo: StationInfo!

	fileprivate struct Track {
		var title: String = ""
		var artist: String = ""
		var isPlaying: Bool = false
	}

	fileprivate struct StationInfo {
		var name: String = ""
		var URL: String = ""
		var shortDesc: String = ""
		var stationArt: Image?
	}


//*****************************************************************
// MARK: - Initialization Functions
//*****************************************************************
	/// Initial setup for SwiftyRadio. Should be included in AppDelegate.swift under `didFinishLaunchingWithOptions`
	open func setup() {
		#if os(iOS) || os(tvOS)
			NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListener(_:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(audioInterruption(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)

			// Set AVFoundation category, required for background audio
			do {
				try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
				try AVAudioSession.sharedInstance().setActive(true)
			} catch {
				print("SwiftyRadio Error: Setting category to AVAudioSessionCategoryPlayback failed")
			}

			setupRemote()
		#endif

		track = Track()
	}

	/// Setup the station, must be called before `Play()`
	/// - parameter name: Name of the station
	/// - parameter URL: The station URL
	/// - parameter shortDesc: A short description of the station **(Not required)**
	/// - parameter artwork: Image to display as album art **(Not required)**
	open func setStation(name: String, URL: String, shortDesc: String = "", artwork: Image = Image()) {
		stationInfo = StationInfo(name: name, URL: URL, shortDesc: shortDesc, stationArt: artwork)
		track.title = stationInfo.shortDesc
		track.artist = stationInfo.name
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

			if #available(iOS 9.1, tvOS 9.1, *) {
				center.changePlaybackPositionCommand.isEnabled = false
			}

			center.playCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
				self.play()
				return MPRemoteCommandHandlerStatus.success
			}

			if #available(iOS 10.0, tvOS 10.0, *) {
				center.pauseCommand.isEnabled = false
				center.togglePlayPauseCommand.isEnabled = false

				center.stopCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
					self.stop()
					return MPRemoteCommandHandlerStatus.success
				}
			} else {
				center.pauseCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
					self.stop()
					return MPRemoteCommandHandlerStatus.success
				}

				center.togglePlayPauseCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
					self.togglePlayStop()
					return MPRemoteCommandHandlerStatus.success
				}
			}
		}
		#endif
	}


//*****************************************************************
// MARK: - General Functions
//*****************************************************************
	/// Get the current playing track title. Use with notification `SwiftyRadioMetadataUpdated`
	/// - returns: Text string of the track title.
	open func trackTitle() -> String {
		return track.title
	}

	/// Get the current playing track artist. Use with notification `SwiftyRadioMetadataUpdated`
	/// - returns: Text string of the track artist.
	open func trackArtist() -> String {
		return track.artist
	}

	/// Get the current playing state
	/// - returns: `True` if SwiftyRadio is playing and `False` if it is not
	open func isPlaying() -> Bool {
		return track.isPlaying
	}

	/// Plays the current set station. Uses notification `SwiftyRadioPlayWasPressed`
	open func play() {
		if stationInfo.URL != "" {
			if !isPlaying() {
				PlayerItem = AVPlayerItem(url: URL(string: stationInfo.URL)!)
				PlayerItem.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
				PlayerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

				Player = AVPlayer(playerItem: PlayerItem)
				Player.play()

				track.isPlaying = true
				NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioPlayWasPressed"), object: nil)
			} else {
				print("SwiftyRadio Error: Station is already playing")
			}
		} else {
			print("SwiftyRadio Error: Station has not been setup")
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
			NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioStopWasPressed"), object: nil)
		} else {
			print("SwiftyRadio Error: Station is already stopped")
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

	/// Set the metadata to custom values. Uses notification `SwiftyRadioMetadataUpdated`
	/// - parameter title: Custom metadata title
	/// - parameter artist: Custom metadata artist **(If not provided the Station Name will be used)**
	open func customMetadata(_ title: String, artist: String = "") {
		track.title = title
		track.artist = artist

		if artist == "" {
			track.artist = stationInfo.name
		}

		updateLockScreen()
		NotificationCenter.default.post(name: Notification.Name(rawValue: "SwiftyRadioMetadataUpdated"), object: nil)
	}

	/// Update the lockscreen with the now playing information
	fileprivate func updateLockScreen() {
		#if os(iOS) || os(tvOS)
			var songInfo = [:] as [String : Any]

			if NSClassFromString("MPNowPlayingInfoCenter") != nil {
				if stationInfo.stationArt != nil {
					let image: UIImage = stationInfo.stationArt!
					var artwork: MPMediaItemArtwork
					if #available(iOS 10.0, tvOS 10.0, *) {
						artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
							return image
						})
					} else {
						artwork = MPMediaItemArtwork(image: image)
					}
					songInfo[MPMediaItemPropertyArtwork] = artwork
				}
				songInfo[MPMediaItemPropertyTitle] = track.title
				songInfo[MPMediaItemPropertyArtist] = track.artist

				if #available(iOS 10.0, tvOS 10.0, *) {
					songInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
				}

				MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
			}
		#elseif os(OSX)
			let notification = NSUserNotification()
			notification.title = stationInfo.name
			notification.subtitle = track.artist
			notification.informativeText = track.title
			notification.identifier = "com.ericconnerapps.SwiftyRadio"
			if stationInfo.stationArt != nil {
				notification.contentImage = stationInfo.stationArt
			}
			NSUserNotificationCenter.default.removeAllDeliveredNotifications()
			NSUserNotificationCenter.default.deliver(notification)
		#endif
	}

	/// Update the now playing artwork
	/// - parameter image: Image to display as album art
	open func updateArtwork(_ image: Image) {
		stationInfo.stationArt = image
		updateLockScreen()
	}

	/// Removes special characters from a text string
	/// - parameter text: Text to be cleaned
	/// - returns: Cleaned text
	fileprivate func clean(_ text: String) -> String {
		let safeChars : Set<Character> = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890'- []".characters)
		return String(text.characters.filter { safeChars.contains($0) })
	}


//*****************************************************************
// MARK: - Notification Functions
//*****************************************************************
	/// Informs the observing object when the value at the specified key path relative to the observed object has changed.
	/// - parameter keyPath: The key path, relative to object, to the value that has changed.
	/// - parameter object: The source object of the key path keyPath.
	/// - parameter change: A dictionary that describes the changes that have been made to the value of the property at the key path keyPath relative to object. Entries are described in Change Dictionary Keys.
	/// - parameter context: The value that was provided when the observer was registered to receive key-value observation notifications.
	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		/// Called when the player item status changes
		if keyPath == "status" {
			if PlayerItem.status == AVPlayerItemStatus.failed {
				stop()
				customMetadata("\(stationInfo.name) is offline", artist: "Please try again later")
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
					track.artist = stationInfo.name
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
					track.artist = stationInfo.name
				}

				// If the track title is still blank use the station description
				if track.title == "" {
					track.title = stationInfo.shortDesc
				}

				print("SwiftyRadio: METADATA - artist: \(track.artist) | title: \(track.title)")

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
				if AVAudioSessionRouteChangeReason.oldDeviceUnavailable.rawValue == audioRouteChangeReason {
					if self.isPlaying() {
						self.stop()
					}

					print("SwiftyRadio: Audio Device was removed")
				}
			})
		}

		/// Called when the current audio is interrupted
		@objc fileprivate func audioInterruption(_ notification: Notification) {
			DispatchQueue.main.async(execute: {
				let audioInterruptionReason = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt

				// Stop audio when a phone call is received
				if AVAudioSessionInterruptionType.began.rawValue == audioInterruptionReason {
					if self.isPlaying() {
						self.stop()
					}

					print("SwiftyRadio: Interruption Began")
				}

				if AVAudioSessionInterruptionType.ended.rawValue == audioInterruptionReason {
					print("SwiftyRadio: Interruption Ended")
				}
			})
		}
	#endif
}
