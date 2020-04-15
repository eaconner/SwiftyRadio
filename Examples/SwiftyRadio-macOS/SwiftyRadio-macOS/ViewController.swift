//
//  ViewController.swift
//  SwiftyRadio-macOS
//
//  Created by Eric Conner on 6/13/17.
//  Copyright © 2017 Eric Conner Apps. All rights reserved.
//

import Cocoa
import SwiftyRadio

// Create a variable for SwiftyRadio
var swiftyRadio: SwiftyRadio = SwiftyRadio()

class ViewController: NSViewController {
	@IBOutlet weak var nowPlayingArtwork: NSImageView!
	@IBOutlet weak var nowPlayingTitle: NSTextField!
	@IBOutlet weak var nowPlayingArtist: NSTextField!
	@IBOutlet weak var btnPlayStop: NSButton!
	
	@IBAction func btnActionPlayStop(_ sender: Any) {
		swiftyRadio.togglePlayStop()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: NSNotification.Name(rawValue: "SwiftyRadioMetadataUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playWasPressed), name: NSNotification.Name(rawValue: "SwiftyRadioPlayWasPressed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopWasPressed), name: NSNotification.Name(rawValue: "SwiftyRadioStopWasPressed"), object: nil)
        
		// Initialize SwiftyRadio
		swiftyRadio.setup()
		
		// Setup Station
        swiftyRadio.setStation(name: "Swifty Radio", URL: "http://198.27.70.42:10042/stream", description: "Simple streaming audio for macOS", artwork: NSImage(named: NSImage.Name(rawValue: "stationArtwork"))!)
	}
	
    @objc func updateView() {
        nowPlayingTitle.stringValue = swiftyRadio.trackTitle()
        nowPlayingArtist.stringValue = swiftyRadio.trackArtist()
        getArtwork(artist: swiftyRadio.trackArtist(), title: swiftyRadio.trackTitle())
    }
    
    @objc func playWasPressed() {
        swiftyRadio.customMetadata("Loading...")
        updateButton()
    }
    
    @objc func stopWasPressed() {
        swiftyRadio.customMetadata("Stopped...")
        updateButton()
    }
    
    func updateButton() {
        if swiftyRadio.isPlaying() {
            btnPlayStop.title = "Stop"
		} else {
            btnPlayStop.title = "Play"
        }
    }
    
    // Get album artwork from iTunes
    func getArtwork(artist: String, title: String) {
        if(artist == "Swifty Radio") {
            DispatchQueue.main.async(execute: {
                self.nowPlayingArtwork.image = NSImage(named: NSImage.Name(rawValue: "stationArtwork"))
                swiftyRadio.updateTrackArtwork(NSImage(named: NSImage.Name(rawValue: "stationArtwork"))!)
                } as @convention(block) () -> Void)
            return
        }
        
        let queryURL: String = String(format: "https://itunes.apple.com/search?term=%@+%@&entity=song&limit=1", artist, title)
        let escapedURL: String = queryURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url: URL = URL(string: escapedURL)!
        
        let session = URLSession.shared
        session.dataTask(with: URLRequest(url: url)) { data, response, error in
            if error != nil {
                print(error!)
            } else {
                do {
                    let data = data
                    let json = try JSONSerialization.jsonObject(with: data!) as? [String: Any]
                    let results = (json as AnyObject)["results"] as? [[String: Any]]
                    var items = [String]()
                    for item in results! {
                        items.append(item["artworkUrl100"]! as! String)
                    }
                    
                    if(items.count > 0) {
                        let iTunesArtworkURL100x100 = items[0]
                        let iTunesArtworkURL600x600 = iTunesArtworkURL100x100.replacingOccurrences(of: "100x100", with: "600x600")
                        DispatchQueue.main.async(execute: {
                            let artworkURL: URL = URL(string: iTunesArtworkURL600x600)!
                            let data = try? Data(contentsOf: artworkURL)
                            self.nowPlayingArtwork.image = NSImage(data: data!)
                            swiftyRadio.updateTrackArtwork(NSImage(data: data!)!)
						} as @convention(block) () -> Void)
                    } else {
                        DispatchQueue.main.async(execute: {
                            self.nowPlayingArtwork.image = NSImage(named: NSImage.Name(rawValue: "stationArtwork"))
                            swiftyRadio.updateTrackArtwork(NSImage(named: NSImage.Name(rawValue: "stationArtwork"))!)
						} as @convention(block) () -> Void)
                    }
                } catch {
                    DispatchQueue.main.async(execute: {
                        self.nowPlayingArtwork.image = NSImage(named: NSImage.Name(rawValue: "stationArtwork"))
                        swiftyRadio.updateTrackArtwork(NSImage(named: NSImage.Name(rawValue: "stationArtwork"))!)
					} as @convention(block) () -> Void)
                }
            }
            }.resume()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}
