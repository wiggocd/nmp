//
//  AppDelegate.swift
//  nmp
//
//  Created by C. Wiggins on 21/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Cocoa
import StoreKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        if NSApplication.shared.windows.count > 0 {
            NSApplication.shared.keyWindow?.close()
        }
    }


}

