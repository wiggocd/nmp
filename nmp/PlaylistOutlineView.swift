//
//  Views.swift
//  nmp
//
//  Created by C. Wiggins on 15/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class PlaylistOutlineView: NSOutlineView {
    let notificationCenter = NotificationCenter.default
    let deleteAnimation: NSTableView.AnimationOptions = .init()
    
    var rowUnderMouse: Int!
    var removedIndexes: IndexSet = []
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        self.rowUnderMouse = self.row(at: point)
        
        if self.rowUnderMouse > -1 {
            let menu = NSMenu()
            let deleteItem = NSMenuItem(title: "Delete", action: #selector(removeRowsConditionally), keyEquivalent: "\u{08}")
            deleteItem.keyEquivalentModifierMask = [.command]
            menu.addItem(deleteItem)
            
            return menu
        }
        
        return nil
    }
    
    @objc func removeRowsConditionally() {
        if self.selectedRowIndexes.count > 0 && self.selectedRowIndexes.contains(self.rowUnderMouse) {
            self.removeSelectedRows()
        } else {
            self.removeCurrentRow()
        }
    }
    
    func removeSelectedRows() {
        self.removedIndexes = self.selectedRowIndexes
        removeItems(at: self.selectedRowIndexes, inParent: nil, withAnimation: self.deleteAnimation)
        self.notificationCenter.post(name: .playlistIndexesRemoved, object: self)
    }
    
    func removeCurrentRow() {
        self.removedIndexes = [self.rowUnderMouse] as IndexSet
        removeItems(at: self.removedIndexes, inParent: nil, withAnimation: self.deleteAnimation)
        self.notificationCenter.post(name: .playlistIndexesRemoved, object: self)
        self.rowUnderMouse = nil
    }
}
