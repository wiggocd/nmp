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
            let deleteItem = NSMenuItem(title: "Delete", action: #selector(removeRowsConditionally), keyEquivalent: "\u{08}")
            deleteItem.keyEquivalentModifierMask = [.command]
            menu.addItem(deleteItem)
            
            return menu
        }
        
        return nil
    }
    
    @objc func removeRowsConditionally() {
        if selectedRowIndexes.count > 0 {
            removeSelectedRows()
        } else {
            removeCurrentRow()
        }
    }
    
    func removeSelectedRows() {
        removedIndexes = selectedRowIndexes
        removeItems(at: selectedRowIndexes, inParent: nil, withAnimation: deleteAnimation)
        notificationCenter.post(name: .playlistIndexesRemoved, object: self)
    }
    
    func removeCurrentRow() {
        removedIndexes = [currentRow] as IndexSet
        removeItems(at: removedIndexes, inParent: nil, withAnimation: deleteAnimation)
        notificationCenter.post(name: .playlistIndexesRemoved, object: self)
        currentRow = nil
    }
}
