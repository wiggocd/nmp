//
//  Slider.swift
//  nmp
//
//  Created by C. Wiggins on 18/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class CustomSliderCell: NSSliderCell {
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        print("Draw")
        var leftRect = rect
        let knob = knobRect(flipped: flipped)
        leftRect.origin = CGPoint(x: 0, y: 2)
        leftRect.size.width = knob.origin.x + knob.size.width
        
        NSColor.lightGray.setFill()
        leftRect.fill()
    }
}

class CustomSlider: NSSlider {
    override class var cellClass: AnyClass? {
        get {
            return CustomSliderCell.self
        } set {
            
        }
    }
}
