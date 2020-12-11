//
//  DefaultViewController.swift
//  nmp
//
//  Created by C. Wiggins on 11/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class DefaultViewController: NSViewController {
    @IBAction func closeWindow(_ sender: Any) {
        if NSApplication.shared.windows.count > 0 {
            NSApplication.shared.keyWindow?.close()
        }
    }
}
