//
//  ViewController.swift
//  SwiftyRadio-tvOS
//
//  Created by Eric Conner on 4/27/20.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Initialize SwiftyRadio
        swiftyRadio.setup()

        // Setup the station
        swiftyRadio.setStation(name: "Classic Rock Florida", URL: "http://198.58.98.83:8258/stream")

        // Start playing the station
        swiftyRadio.play()
    }


}

