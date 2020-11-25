//
//  ViewController.swift
//  SwiftyRadio-iOS
//
//  Created by Eric Conner on 4/27/20.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var albumArtView: UIImageView!
    @IBOutlet weak var nowPlayingArtist: UILabel!
    @IBOutlet weak var nowPlayingTitle: UILabel!
    @IBOutlet weak var btnPlayStop: UIButton!
    
    @IBAction func btnActionPlayStop() {
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

        // Setup the station
        swiftyRadio.setStation(name: "Classic Rock 109", URL: "http://listen.classicrock109.com:10042", artwork: UIImage(imageLiteralResourceName: "LaunchScreen"))
        
        albumArtView.image = UIImage(imageLiteralResourceName: "LaunchScreen")
        albumArtView.layer.cornerRadius = self.albumArtView.frame.size.width / 20
        albumArtView.clipsToBounds = true
                
        btnPlayStop.layer.cornerRadius = btnPlayStop.frame.size.height / 4
        
        swiftyRadio.customMetadata("Press Play to begin...")
        updateButton()
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
    
    @objc func updateView() {
        nowPlayingTitle.text = swiftyRadio.trackTitle()
        nowPlayingArtist.text = swiftyRadio.trackArtist()
        getArtwork(artist: swiftyRadio.trackArtist(), title: swiftyRadio.trackTitle())
    }
    
    // Get album artwork from iTunes
    func getArtwork(artist: String, title: String) {
        if(artist == "Swifty Radio") {
            DispatchQueue.main.async(execute: {
                self.albumArtView.image = swiftyRadio.stationArtwork()
                swiftyRadio.updateTrackArtwork(swiftyRadio.stationArtwork())
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
                            self.albumArtView.image = UIImage(data: data!)
                            swiftyRadio.updateTrackArtwork(UIImage(data: data!)!)
                        } as @convention(block) () -> Void)
                    } else {
                        DispatchQueue.main.async(execute: {
                            self.albumArtView.image = swiftyRadio.stationArtwork()
                            swiftyRadio.updateTrackArtwork(swiftyRadio.stationArtwork())
                        } as @convention(block) () -> Void)
                    }
                } catch {
                    DispatchQueue.main.async(execute: {
                        self.albumArtView.image = swiftyRadio.stationArtwork()
                        swiftyRadio.updateTrackArtwork(swiftyRadio.stationArtwork())
                    } as @convention(block) () -> Void)
                }
            }
        }.resume()
    }

}

