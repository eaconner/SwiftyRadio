# SwiftyRadio

![Swift3](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat")
[![Version](https://img.shields.io/cocoapods/v/SwiftyRadio.svg?style=flat)](http://cocoapods.org/pods/SwiftyRadio)
[![License](https://img.shields.io/cocoapods/l/SwiftyRadio.svg?style=flat)](http://cocoapods.org/pods/SwiftyRadio)
[![Platform](https://img.shields.io/cocoapods/p/SwiftyRadio.svg?style=flat)](http://cocoapods.org/pods/SwiftyRadio)

## Installation
### Manual
Just drop the **SwiftyRadio.swift** file into your project. That's it!

### CocoaPods
[CocoaPods] is a dependency manager for Cocoa projects. To install SwiftyRadio with CocoaPods:

 1. Make sure CocoaPods is [installed][CocoaPods Installation].

 2. Update your Podfile to include the following:

    ```ruby
    use_frameworks!
    pod 'SwiftyRadio'
    ```

 3. Run `pod install`.

 4. In your code import SwiftyRadio like so:
	`import SwiftyRadio`

### Swift Package Manager

The [Swift Package Manager] is a tool for managing the distribution of Swift code.

 1. Update your `Package.swift` file to include the following:

	```swift
	import PackageDescription

	let package = Package(
		name: "My Radio App",
		dependencies: [
			.Package(url: "https://github.com/EricConnerApps/SwiftyRadio.git"),
		]
	)
	 ```

 2. Run `swift build`.

## Prerequisites

In order to support background mode, append the following to your `Info.plist`:
```plist
<key>UIBackgroundModes</key>
<array>
	<string>audio</string>
</array>
```

If you want to stream from `http://` URLs, append the following to your `Info.plist`:
```plist
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSAllowsArbitraryLoads</key>
	<true/>
</dict>
```

## Usage

In `AppDelegate.swift` add the following code after imports and before `@UIApplicationMain`.
```swift
// Create a variable for SwiftyRadio
var swiftyRadio: SwiftyRadio = SwiftyRadio()
```

In `ViewController.swift` include the following code in `viewDidLoad()`
```swift
// Initialize SwiftyRadio
swiftyRadio.setup()

// Setup the station
swiftyRadio.setStation("Classic Rock 109", URL: "http://198.27.70.42:10042/stream")

// Start playing the station
swiftyRadio.play()
```

## Handling Remote Events

In order to handle remote events, you should do the following:

In `AppDelegate.swift` add the following code in `didFinishLaunchingWithOptions`:
`UIApplication.shared.beginReceivingRemoteControlEvents()`

Then add the following code in `applicationWillTerminate`:
`UIApplication.shared.endReceivingRemoteControlEvents()`

## Examples

- [SwiftyRadio-iOS](https://github.com/EricConnerApps/SwiftyRadio-iOS)
- [SwiftyRadio-tvOS](https://github.com/EricConnerApps/SwiftyRadio-tvOS)
- [SwiftyRadio-macOS](https://github.com/EricConnerApps/SwiftyRadio-macOS)

## Changelog

All notable changes to this project will be documented in [CHANGELOG.md].

## License

SwiftyRadio is available under the MIT license. See the [LICENSE] file for more info.

## Want to help?

Got a bug fix, or a new feature? Create a pull request and go for it!

## Let me know!

If you use SwiftyRadio, please let me know about your app.

[CHANGELOG.md]: https://github.com/EricConnerApps/SwiftyRadio/blob/master/CHANGELOG.md
[LICENSE]: https://github.com/EricConnerApps/SwiftyRadio/blob/master/LICENSE
[Swift Package Manager]: https://swift.org/package-manager/
[CocoaPods]: https://cocoapods.org
[CocoaPods Installation]: https://guides.cocoapods.org/using/getting-started.html#getting-started
