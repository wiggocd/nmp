//
//  HelpViewDataSource.swift
//  nmp
//
//  Created by C. Wiggins on 11/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

extension HelpViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.actionsTableItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView
        
        if cell != nil {
            if tableColumn == tableView.tableColumns[0] {
                cell?.textField?.stringValue = self.actionsTableItems[row].0
            } else {
                cell?.textField?.stringValue = self.actionsTableItems[row].1
            }
            
            return cell
        }
        
        return nil
    }
}
