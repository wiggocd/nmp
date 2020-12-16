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
    let deleteAnimation: NSTableView.AnimationOptions = .effectFade
    
    var currentRow: Int!
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        currentRow = self.row(at: point)
        
        let menu = NSMenu()
        let deleteItem = NSMenuItem(title: "Delete", action: #selector(removeCurrentRow), keyEquivalent: "\u{08}")
        deleteItem.keyEquivalentModifierMask = [.command]
        menu.addItem(deleteItem)
        
        return menu
    }
    
    func removeSelectedRows() {
        removeItems(at: selectedRowIndexes, inParent: nil, withAnimation: deleteAnimation)
    }
    
    @objc func removeCurrentRow() {
        removeItems(at: [currentRow], inParent: nil, withAnimation: deleteAnimation)
        currentRow = nil
    }
}
