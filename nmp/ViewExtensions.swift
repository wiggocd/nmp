//
//  Views.swift
//  nmp
//
//  Created by C. Wiggins on 21/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

extension NSView {
    func roundCorners(withRadius radius: CGFloat) {
        self.wantsLayer = true
        self.layer?.cornerRadius = radius
    }
}

extension NSTextView {
    func disableWrapping() {
        self.isHorizontallyResizable = true
        self.textContainer?.widthTracksTextView = false
    }
}
