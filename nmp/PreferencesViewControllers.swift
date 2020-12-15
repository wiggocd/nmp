//
//  PreferencesViewControllers.swift
//  nmp
//
//  Created by C. Wiggins on 15/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class OptionsViewController: NSViewController {
    let application = NSApplication.shared as? Application
    let notificationCenter = NotificationCenter.default
    
    @IBOutlet weak var colorBgButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if application!.colorBg! {
            colorBgButton.state = .on
        } else {
            colorBgButton.state = .off
        }
    }
    
    @IBAction func colorBgAction(_ sender: Any) {
        if let sender = sender as? NSButton {
            if sender.state.rawValue == 1 {
                application?.colorBg = true
            } else {
                application?.colorBg = false
            }
            
            notificationCenter.post(name: .preferencesChanged, object: nil)
        }
    }
}
