//
//  CustomSliderCells.swift
//  nmp
//
//  Created by C. Wiggins on 19/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class CustomSlider: NSSlider {
    override func setNeedsDisplay(_ invalidRect: NSRect) {
        super.setNeedsDisplay(bounds)
    }
}

class CustomSliderCell: NSSliderCell {
    var barHeight: CGFloat = 3
    var barRadius: CGFloat = 2.5
    var backgroundColor = NSColor.gray.withAlphaComponent(0.5)
    var filledColor = NSColor.lightGray
    
    var position: CGFloat {
        get {
            return self.doubleValue.isNormal && self.minValue.isNormal && self.maxValue.isNormal ?
                CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue)) : 0.0
        }
    }
}

class TimeSliderCell: CustomSliderCell {
    var knobRadius: CGFloat = 1.2
    var knobColor = NSColor.lightGray
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        var newRect = rect
        newRect.size.height = self.barHeight
        
        let value = self.position
        
        let finalWidth = value * controlView!.frame.width
        
        var leftRect = newRect
        leftRect.size.width = finalWidth
        
        let bg = NSBezierPath(roundedRect: newRect, xRadius: self.barRadius, yRadius: self.barRadius)
        self.backgroundColor.setFill()
        bg.fill()
        
        let active = NSBezierPath(roundedRect: leftRect, xRadius: self.barRadius, yRadius: self.barRadius)
        self.filledColor.setFill()
        active.fill()
    }
    
    override func drawKnob(_ knobRect: NSRect) {
        let size = NSSize(width: knobRect.width, height: knobRect.height / 3)
        let rect = NSRect(x: knobRect.minX, y: knobRect.minY + size.height / 1.5, width: size.width, height: size.height)
        let path = NSBezierPath(roundedRect: rect, xRadius: self.knobRadius, yRadius: self.knobRadius)
        self.knobColor.setFill()
        path.fill()
    }
}

class VolumeSliderCell: CustomSliderCell {
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        var newRect = rect
        newRect.size.height = self.barHeight
        
        let value = self.position
        
        let finalWidth = value * controlView!.frame.width - 5
        
        var leftRect = newRect
        leftRect.size.width = finalWidth
        
        let bg = NSBezierPath(roundedRect: newRect, xRadius: self.barRadius, yRadius: self.barRadius)
        self.backgroundColor.setFill()
        bg.fill()
        
        let active = NSBezierPath(roundedRect: leftRect, xRadius: self.barRadius, yRadius: self.barRadius)
        self.filledColor.setFill()
        active.fill()
    }
}
