//
//  ViewController.swift
//  SwiftyRadio-tvOS
//
//  Created by Eric Conner on 6/13/17.
//  Copyright © 2017 Eric Conner Apps. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var nowPlayingArtwork: UIImageView!
    @IBOutlet weak var nowPlayingTrackTitle: UILabel!
    @IBOutlet weak var nowPlayingTrackArtist: UILabel!
    @IBOutlet weak var btnPlayStop: UIButton!
    
    @IBAction func btnActioPlayStop() {
        swiftyRadio.togglePlayStop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: NSNotification.Name(rawValue: "SwiftyRadioMetadataUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playWasPressed), name: NSNotification.Name(rawValue: "SwiftyRadioPlayWasPressed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopWasPressed), name: NSNotification.Name(rawValue: "SwiftyRadioStopWasPressed"), object: nil)
        
        nowPlayingArtwork.layer.cornerRadius = nowPlayingArtwork.frame.size.width / 40
        nowPlayingArtwork.clipsToBounds = true
        
        btnPlayStop.layer.cornerRadius = btnPlayStop.frame.size.height / 4
        
        swiftyRadio.setStation(name: "Swifty Radio", URL: "http://198.27.70.42:10042/stream", description: "Simple streaming audio for tvOS", artwork: UIImage(named: "stationArtwork")!)
    }
    
    @objc func updateView() {
        nowPlayingTrackTitle.text = swiftyRadio.trackTitle()
        nowPlayingTrackArtist.text = swiftyRadio.trackArtist()
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
            btnPlayStop.setTitle("Stop", for: .normal)
        } else {
            btnPlayStop.setTitle("Play", for: .normal)
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for item in presses {
            if item.type == .playPause {
                swiftyRadio.togglePlayStop()
            }
            if item.type == .menu {
                UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
            }
        }
    }
    
    // Get album artwork from iTunes
    func getArtwork(artist: String, title: String) {
        if(artist == "Swifty Radio") {
            DispatchQueue.main.async(execute: {
                self.nowPlayingArtwork.image = UIImage(named: "stationArtwork")
				swiftyRadio.updateTrackArtwork(UIImage(named: "stationArtwork")!)
                } as @convention(block) () -> Void)
            return
        }
        
        let queryURL: String = String(format: "https://itunes.apple.com/search?term=%@+%@&entity=song", artist, title)
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
                            self.nowPlayingArtwork.image = UIImage(data: data!)
							swiftyRadio.updateTrackArtwork(UIImage(data: data!)!)
                            } as @convention(block) () -> Void)
                    } else {
                        DispatchQueue.main.async(execute: {
                            self.nowPlayingArtwork.image = UIImage(named: "stationArtwork")
							swiftyRadio.updateTrackArtwork(UIImage(named: "stationArtwork")!)
                            } as @convention(block) () -> Void)
                    }
                } catch {
                    DispatchQueue.main.async(execute: {
                        self.nowPlayingArtwork.image = UIImage(named: "stationArtwork")
						swiftyRadio.updateTrackArtwork(UIImage(named: "stationArtwork")!)
                        } as @convention(block) () -> Void)
                }
            }
            }.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
