//
//  Application.swift
//  nmp
//
//  Created by C. Wiggins on 11/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

@objc(Application)
class Application: NSApplication {
    let notificationCenter = NotificationCenter.default
    let userDefaults = UserDefaults.standard
    
    var colorBg: Bool! {
        didSet {
            userDefaults.set(colorBg, forKey: "ColorBg")
        }
    }
    
    var showTransparentAppearance: Bool! {
        didSet {
            userDefaults.set(showTransparentAppearance, forKey: "ShowTransparentAppearance")
        }
    }
    
    override init() {
        super.init()
        initialiseUserDefaults()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func initialiseUserDefaults() {
        if userDefaults.value(forKey: "Volume") == nil {
            userDefaults.set(1.0, forKey: "Volume")
        }
        
        if userDefaults.value(forKey: "ColorBg") == nil {
            colorBg = true
        } else {
            colorBg = userDefaults.bool(forKey: "ColorBg")
        }
        
        if userDefaults.value(forKey: "ShowTransparentAppearance") == nil {
            showTransparentAppearance = true
        } else {
            showTransparentAppearance = userDefaults.bool(forKey: "ShowTransparentAppearance")
        }
    }
    
    func resetUserDefaults() {
        userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
}
