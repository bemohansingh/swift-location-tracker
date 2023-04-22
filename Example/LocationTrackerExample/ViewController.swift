//
//  ViewController.swift
//  LocationTrackerExample
//
//  Created by bemohansingh on 27/12/2021.
//

import UIKit

class ViewController: UIViewController {
    
    
    private var appDelegate: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
  

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        appDelegate.tracker.startTrackingLocation()
    }


}

