//
//  Views.swift
//  nmp
//
//  Created by C. Wiggins on 15/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class NonUserScrollableScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        return
    }
}

class PlaylistOutlineView: NSOutlineView {
    let notificationCenter = NotificationCenter.default
    let deleteAnimation: NSTableView.AnimationOptions = .init()
    
    var currentRow: Int!
    var removedIndexes: IndexSet = []
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        currentRow = self.row(at: point)
        
        if currentRow > -1 {
            let menu = NSMenu()
            let deleteItem = NSMenuItem(title: "Delete", action: #selector(removeCurrentRow), keyEquivalent: "\u{08}")
            deleteItem.keyEquivalentModifierMask = [.command]
            menu.addItem(deleteItem)
            
            return menu
        }
        
        return nil
    }
    
    func removeSelectedRows() {
        removedIndexes = selectedRowIndexes
        removeItems(at: selectedRowIndexes, inParent: nil, withAnimation: deleteAnimation)
        notificationCenter.post(name: .playlistIndexesRemoved, object: self)
    }
    
    @objc func removeCurrentRow() {
        removedIndexes = [currentRow] as IndexSet
        removeItems(at: removedIndexes, inParent: nil, withAnimation: deleteAnimation)
        notificationCenter.post(name: .playlistIndexesRemoved, object: self)
        currentRow = nil
    }
}

class CustomSliderCell: NSSliderCell {
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let barRadius = CGFloat(2.5)
        let value = CGFloat((doubleValue - minValue) / (maxValue - minValue))
        let finalWidth = value * ((controlView?.frame.size.width)! - 8)
        
        var leftRect = rect
        leftRect.size.width = finalWidth
        
        let bg = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
        NSColor.darkGray.setFill()
        bg.fill()
        
        let active = NSBezierPath(roundedRect: leftRect, xRadius: barRadius, yRadius: barRadius)
        NSColor.white.setFill()
        active.fill()
    }
}
