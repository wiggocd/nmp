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
            self.application?.userDefaults.set(self.selectedTabViewItemIndex, forKey: "PreferencesSelectedTabViewItemIndex")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialiseSelectedTab()
    }
    
    func initialiseSelectedTab() {
        if let index = self.application?.userDefaults.integer(forKey: "PreferencesSelectedTabViewItemIndex") {
            self.selectedTabViewItemIndex = index
        } else {
            self.selectedTabViewItemIndex = 0
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
        
        if self.application!.colorBg! {
            self.colorBgButton.state = .on
        } else {
            self.colorBgButton.state = .off
        }
        
        if self.application!.showTransparentAppearance! {
            self.transparentAppearanceButton.state = .on
        } else {
            self.transparentAppearanceButton.state = .off
        }
    }
    
    @IBAction func colorBgAction(_ sender: Any) {
        if let sender = sender as? NSButton {
            if sender.state == .on {
                self.application?.colorBg = true
            } else {
                self.application?.colorBg = false
            }
            
            self.notificationCenter.post(name: .preferencesChanged, object: nil)
        }
    }
    
    @IBAction func transparentAppearanceAction(_ sender: Any) {
        if let sender = sender as? NSButton {
            if sender.state == .on {
                self.application?.showTransparentAppearance = true
            } else {
                self.application?.showTransparentAppearance = false
            }
            
            self.notificationCenter.post(name: .preferencesChanged, object: nil)
        }
    }
}

class AdvancedPreferencesViewController: NSViewController {
    let application = NSApplication.shared as? Application
    let notificationCenter = NotificationCenter.default
    
    @IBAction func resetUserDefaultsAction(_ sender: Any) {
        self.application?.resetUserDefaults()
    }
}
