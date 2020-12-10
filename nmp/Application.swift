//
//  Application.swift
//  nmp
//
//  Created by Kate Wiggins on 10/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

@objc(Application)
class Application: NSApplication {
    let notificationCenter = NotificationCenter.default
    
    func mediaKeyEvent(key: Int, state: Bool) {
        switch Int32(key) {
        case NX_KEYTYPE_PLAY:
            if state == false {
                notificationCenter.post(name: .playPause, object: nil)
            }
            break
        default:
            break
        }
    }
    
    override func sendEvent(_ event: NSEvent) {
        if event.type.rawValue == NX_SYSDEFINED && event.subtype.rawValue == NX_SUBTYPE_AUX_CONTROL_BUTTONS {
            let keyCode = (event.data1 & 0xFFFF0000) >> 16
            let keyFlags = event.data1 & 0x0000FFFF
            let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA
            
            mediaKeyEvent(key: keyCode, state: keyState)
        }
        super.sendEvent(event)
    }
}
