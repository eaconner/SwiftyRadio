# Changelog
All notable changes to this project will be documented in this file.

## [1.4.9] - 2018-06-07
- Moved project from GitHub to BitBucket

## 1.4.8

## 1.4.7

## 1.4.6 - 2017-10-30
- Cleaned up `setupRemote()` and `updateLockScreen()`
- Added example code for iOS, tvOS & macOS


## 1.4.5 - 2017-10-29
### Changed
- Added better support for `MPRemoteCommandCenter` with Apple Watch and Air Pods.


## 1.4.4 - 2017-06-26
### Changed
- Fixed album art display on macOS


## 1.4.3 - 2017-06-19
### Added
- `trackArtwork()` and `updateTrackArtwork()`
- `stationArtwork()` and `updateStationArtwork()`
- Clear track data when `stop()` is called

### Changed
- Re-organized and re-named variables
- Re-worked `updateLockScreen()` to work with `track.artwork` and `station.artwork`
- Added more documentation to `README.md`


## 1.4.2 - 2017-06-15
### Changed
- `MPRemoteCommandCenter` now shows play/stop instead of play/pause on iOS v10.0 / tvOS v10.0


## 1.4.1 - 2017-06-14
### Changed
- Works with tvOS v9.0


## 1.4 - 2017-06-14
### Added
- Better image support
- Included `MPRemoteCommandCenter` in `setup()`
- Station Image should now be visible in macOS notifications
- CHANGELOG.md
- Swift Package Manager support

### Changed
- func `pause()` to `stop()`
- func `togglePlayPause()` to `togglePlayStop()`
- notification `SwiftyRadioPauseWasPressed` to `SwiftyRadioStopWasPressed`


## 1.3.1 - 2017-06-13
- Reviewed entire project

### Added
- CocoaPods support


[1.4.9]: https://bitbucket.org/ericconnerapps/swiftyradio/compare/1.4.9%0D1.4.8#diff