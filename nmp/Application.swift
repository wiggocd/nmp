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
            userDefaults.set(colorBg, forKey: "colorBg")
        }
    }
    
    var showTransparentAppearance: Bool! {
        didSet {
            userDefaults.set(showTransparentAppearance, forKey: "showTransparentAppearance")
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
        if userDefaults.value(forKey: "colorBg") == nil {
            colorBg = true
        } else {
            colorBg = userDefaults.bool(forKey: "colorBg")
        }
        
        if userDefaults.value(forKey: "showTransparentAppearance") == nil {
            showTransparentAppearance = false
        } else {
            showTransparentAppearance = userDefaults.bool(forKey: "showTransparentAppearance")
        }
    }
    
    func resetUserDefaults() {
        userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
}
