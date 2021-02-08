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
        self.initialiseSelectedTab()
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
    
    let appearanceNames = [
        "System",
        "Light",
        "Dark"
    ]
    
    let appearances = [
        "System": NSApplication.shared.appearance,
        "Light": NSAppearance(named: .aqua),
        "Dark": NSAppearance(named: .darkAqua)
    ]
    
    
    @IBOutlet weak var appearancePopUp: NSPopUpButton!
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
        
        self.initialisePopUpMenus()
    }
    
    func initialisePopUpMenus() {
        self.appearancePopUp.removeAllItems()
        self.appearancePopUp.addItems(withTitles: appearanceNames)
        
        if let appearanceName = self.application?.userDefaults.string(forKey: "NSAppearanceName") {
            switch appearanceName.replacingOccurrences(of: "NSAppearanceName", with: "") {
            case "DarkAqua":
                if self.appearanceNames.contains("Dark") {
                    self.appearancePopUp.selectItem(withTitle: "Dark")
                }
            case "Aqua":
                if self.appearanceNames.contains("Light") {
                    self.appearancePopUp.selectItem(withTitle: "Light")
                }
            default:
                if self.appearanceNames.contains("System") {
                    self.appearancePopUp.selectItem(withTitle: "System")
                }
            }
            
            if let title = self.appearancePopUp.titleOfSelectedItem { self.appearancePopUp.title = title }
        } else if self.appearancePopUp.itemArray.count > 0 {
            if self.appearanceNames.contains("System") {
                self.appearancePopUp.selectItem(withTitle: "System")
                if let title = self.appearancePopUp.titleOfSelectedItem { self.appearancePopUp.title = title }
            }
        }
    }
    
    @IBAction func appearanceSelectionChanged(_ sender: Any) {
        if let selectedTitle = self.appearancePopUp.titleOfSelectedItem,
           self.appearanceNames.contains(selectedTitle) {
            if selectedTitle == "System" {
                self.application?.appearance = NSAppearance()
                self.application?.userDefaults.removeObject(forKey: "NSAppearanceName")
            }
            
            self.application?.appearance = self.appearances[selectedTitle] as? NSAppearance
            self.notificationCenter.post(name: .preferencesChanged, object: nil)
            self.appearancePopUp.title = selectedTitle
            self.application?.userDefaults.setValue(self.application?.appearance?.name, forKey: "NSAppearanceName")
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
