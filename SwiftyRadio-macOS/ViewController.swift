//
//  ViewController.swift
//  SwiftyRadio-macOS
//
//  Created by Eric Conner on 4/27/20.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Initialize SwiftyRadio
        swiftyRadio.setup()

        // Setup the station
        swiftyRadio.setStation(name: "Classic Rock 109", URL: "http://listen.classicrock109.com:10042")

        // Start playing the station
        swiftyRadio.play()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

