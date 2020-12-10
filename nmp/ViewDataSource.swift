//
//  ViewDataSources.swift
//  nmp
//
//  Created by Kate Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

extension ViewController: NSOutlineViewDataSource, NSPasteboardItemDataProvider {
    // MARK: View cells
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if ((item as? PlaylistItem) != nil) {
            return 1
        } else {
            return playlistItems.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? PlaylistItem {
            return item
        } else {
            return playlistItems[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = outlineView.makeView(withIdentifier: tableColumn!.identifier, owner: tableColumn?.headerCell) as? NSTableCellView // Returns nil if no view cell is in place within interface builder
        
        if let item = item as? PlaylistItem {
            cell?.textField?.stringValue = item.name
        }
        
        cell?.textField?.textColor = NSColor.controlTextColor
        
        return cell
    }
    
    // MARK: Drag & Drop
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pbItem: NSPasteboardItem = NSPasteboardItem()
        pbItem.setDataProvider(self, forTypes: [REORDER_PASTEBOARD_TYPE])
        return pbItem
    }
    
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        draggedNode = draggedItems[0] as AnyObject
        session.draggingPasteboard.setData(Data(), forType: REORDER_PASTEBOARD_TYPE)
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        var ret: NSDragOperation = NSDragOperation()
        
        // let baseItem = item as? PlaylistItem
        
        if item as AnyObject? !== draggedNode && index != NSOutlineViewDropOnItemIndex {
            if let _ = draggedNode as? PlaylistItem {
                ret = NSDragOperation.generic
            }
        }
        
        return ret
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        var ret: Bool = false
        
        if !(draggedNode is PlaylistItem) {
            return false
        }
        
        let srcItem = draggedNode as! PlaylistItem
        let destItem: PlaylistItem? = item as? PlaylistItem
        let oldIndex = outlineView.row(forItem: srcItem)
        var toIndex = index > oldIndex ? index - 1 : index
        
        if toIndex == NSOutlineViewDropOnItemIndex {        // Should never occur
            toIndex = 0
        }
        
        if oldIndex != toIndex || srcItem != destItem {
            player.movePlaylistItem(fromIndex: oldIndex, toIndex: toIndex)
            playlistOutlineView.reloadData()
            ret = true
        }
        
        return ret
    }
    
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggedNode = nil
    }
    
    // MARK: NSPasteboardItemDataProvider
    
    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        let string = "Outline Pasteboard Item"
        item.setString(string, forType: type)
    }
}
