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
    
    let shadowRadius: CGFloat = 8
    let UICornerRadius: CGFloat = 4
    let bgBlurRadius: CGFloat = 50
    let animationDuration: TimeInterval = 0.5
    
    var colorBg: Bool! {
        didSet {
            self.userDefaults.set(colorBg, forKey: "ColorBg")
        }
    }
    
    var showTransparentAppearance: Bool! {
        didSet {
            self.userDefaults.set(showTransparentAppearance, forKey: "ShowTransparentAppearance")
        }
    }
    
    override init() {
        super.init()
        self.initialiseUserDefaults()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func initialiseUserDefaults() {
        if self.userDefaults.value(forKey: "Volume") == nil {
            self.userDefaults.set(1.0, forKey: "Volume")
        }
        
        if self.userDefaults.value(forKey: "ColorBg") == nil {
            self.colorBg = true
        } else {
            self.colorBg = self.userDefaults.bool(forKey: "ColorBg")
        }
        
        if self.userDefaults.value(forKey: "ShowTransparentAppearance") == nil {
            self.showTransparentAppearance = true
        } else {
            self.showTransparentAppearance = self.userDefaults.bool(forKey: "ShowTransparentAppearance")
        }
    }
    
    func resetUserDefaults() {
        self.userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
}
