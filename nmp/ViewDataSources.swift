//
//  ViewDataSources.swift
//  nmp
//
//  Created by Kate Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import AppKit

extension ViewController {
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
    
    // Todo: add drag and drop data sources
}
