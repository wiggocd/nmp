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
    
    override func mouseDown(with event: NSEvent) {
        if let cell = self.cell as? CustomSliderCell { cell.mouseDown = true }
        super.mouseDown(with: event)
        if let cell = self.cell as? CustomSliderCell { cell.mouseDown = false }
    }
}

class CustomSliderCell: NSSliderCell {
    var barHeight: CGFloat = 3
    var barRadius: CGFloat = 2.5
    var backgroundColor = NSColor.gray.withAlphaComponent(0.5)
    var filledColor = NSColor.gray.withAlphaComponent(0.7)
    var mouseDown = false
    var barRect: NSRect?
    
    var position: CGFloat {
        get {
            return self.doubleValue.isNormal && self.minValue.isNormal && self.maxValue.isNormal ?
                CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue)) : 0.0
        }
    }
}

class TimeSliderCell: CustomSliderCell {
    var knobRadius: CGFloat = 1.2
    var standardKnobColor = NSColor.lightGray
    var alternateKnobColor = NSColor.gray
    var knobColor: NSColor {
        get {
            if self.mouseDown {
                return self.alternateKnobColor
            } else {
                return self.standardKnobColor
            }
        }
    }
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        var newRect = rect
        newRect.size.height = self.barHeight
        
        let bg = NSBezierPath(roundedRect: newRect, xRadius: self.barRadius, yRadius: self.barRadius)
        self.backgroundColor.setFill()
        bg.fill()
        
        self.barRect = newRect
    }
    
    override func drawKnob(_ knobRect: NSRect) {
        if let barRect = self.barRect {
            let filledRect = NSRect(x: barRect.minX, y: barRect.minY, width: knobRect.minX, height: barRect.height)
            let active = NSBezierPath(roundedRect: filledRect, xRadius: self.barRadius, yRadius: self.barRadius)
            self.filledColor.setFill()
            active.fill()
        }
        
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
        
        let bg = NSBezierPath(roundedRect: newRect, xRadius: self.barRadius, yRadius: self.barRadius)
        self.backgroundColor.setFill()
        bg.fill()
        
        self.barRect = newRect
    }
    
    override func drawKnob(_ knobRect: NSRect) {
        if let barRect = self.barRect {
            let filledRect = NSRect(x: barRect.minX, y: barRect.minY, width: knobRect.minX, height: barRect.height)
            let active = NSBezierPath(roundedRect: filledRect, xRadius: self.barRadius, yRadius: self.barRadius)
            self.filledColor.setFill()
            active.fill()
        }
        
        super.drawKnob(knobRect)
    }
}
