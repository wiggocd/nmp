//
//  ViewDataSources.swift
//  nmp
//
//  Created by C. Wiggins on 06/12/2020.
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
    
    // MARK: Playlist Drag & Drop
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pbItem: NSPasteboardItem = NSPasteboardItem()
        pbItem.setDataProvider(self, forTypes: [REORDER_PASTEBOARD_TYPE])
        return pbItem
    }
    
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        draggedNodes = draggedItems as [AnyObject]
        session.draggingPasteboard.setData(Data(), forType: REORDER_PASTEBOARD_TYPE)
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        var ret: NSDragOperation = NSDragOperation()
        
        if index != NSOutlineViewDropOnItemIndex {
            if item as AnyObject? !== draggedNodes as AnyObject? {
                if let _ = draggedNodes as? [PlaylistItem] {
                    ret = NSDragOperation.generic
                }
            } else if info.draggingPasteboard.pasteboardItems != nil {
                ret = NSDragOperation.copy
            }
        }
        
        return ret
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        var ret: Bool = false
        
        if draggedNodes != nil {
            if !(draggedNodes is [PlaylistItem]) {
                return false
            }
            
            let srcItems = draggedNodes as! [PlaylistItem]
            let destItem: PlaylistItem? = item as? PlaylistItem
            let oldIndex = outlineView.row(forItem: srcItems[0])
            var toIndex = index > oldIndex ? index - 1 : index
            
            if toIndex == NSOutlineViewDropOnItemIndex {        // Should never occur
                toIndex = 0
            }
            
            if oldIndex != toIndex || srcItems[0] != destItem {
                player.movePlaylistItems(fromIndex: oldIndex, toIndex: toIndex, count: srcItems.count)
                playlistOutlineView.reloadData()
                ret = true
            }
        } else {
            if info.draggingPasteboard.pasteboardItems != nil {
                let pbItems = info.draggingPasteboard.pasteboardItems
                var urls: [URL?] = []
                for item in pbItems! {
                    if let data = item.propertyList(forType: FILENAMES_PASTEBOARD_TYPE) as? String {
                        if let url = URL(string: data) {
                            urls.append(url)
                        }
                    }
                }
                
                urls = sortUrls(urls: recurseSubdirectories(urls: urls))
                player.addMedia(urls: urls, updateIndexIfNew: true, shouldPlay: true)
            }
        }
        
        return ret
    }
    
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggedNodes = nil
    }
    
    // MARK: NSPasteboardItemDataProvider
    
    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        let string = "Pasteboard Item"
        item.setString(string, forType: type)
    }
}
