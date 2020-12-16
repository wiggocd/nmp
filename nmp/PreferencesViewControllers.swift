//
//  PreferencesViewControllers.swift
//  nmp
//
//  Created by C. Wiggins on 15/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class PreferencesTabViewController: NSTabViewController {
    let application = NSApplication.shared as? Application
    
    override var selectedTabViewItemIndex: Int {
        didSet {
            print("Index changed")
            application?.userDefaults.set(selectedTabViewItemIndex, forKey: "PreferencesSelectedTabViewItemIndex")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialiseSelectedTab()
    }
    
    func initialiseSelectedTab() {
        if let index = application?.userDefaults.integer(forKey: "PreferencesSelectedTabViewItemIndex") {
            selectedTabViewItemIndex = index
        } else {
            selectedTabViewItemIndex = 0
        }
    }
}

class GeneralPreferencesViewController: NSViewController {
    let application = NSApplication.shared as? Application
    let notificationCenter = NotificationCenter.default
    
    @IBOutlet weak var colorBgButton: NSButton!
    @IBOutlet weak var transparentAppearanceButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if application!.colorBg! {
            colorBgButton.state = .on
        } else {
            colorBgButton.state = .off
        }
        
        if application!.showTransparentAppearance! {
            transparentAppearanceButton.state = .on
        } else {
            transparentAppearanceButton.state = .off
        }
    }
    
    @IBAction func colorBgAction(_ sender: Any) {
        if let sender = sender as? NSButton {
            if sender.state == .on {
                application?.colorBg = true
            } else {
                application?.colorBg = false
            }
            
            notificationCenter.post(name: .preferencesChanged, object: nil)
        }
    }
    
    @IBAction func transparentAppearanceAction(_ sender: Any) {
        if let sender = sender as? NSButton {
            if sender.state == .on {
                application?.showTransparentAppearance = true
            } else {
                application?.showTransparentAppearance = false
            }
            
            notificationCenter.post(name: .preferencesChanged, object: nil)
        }
    }
}

class AdvancedPreferencesViewController: NSViewController {
    let application = NSApplication.shared as? Application
    let notificationCenter = NotificationCenter.default
    
    @IBAction func resetUserDefaultsAction(_ sender: Any) {
        application?.resetUserDefaults()
    }
}
