//
//  HelpViewController.swift
//  nmp
//
//  Created by C. Wiggins on 11/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class HelpViewController: NSViewController {
    @IBOutlet weak var actionsTableView: NSTableView!
    
    let actionsTableItems = [
        ("Play/Pause", "Space"),
        ("Clear Playlist", "Shift+⌘+←")
    ]
    
    override func viewDidLoad() {
        self.actionsTableView.delegate = self
        self.actionsTableView.dataSource = self
        self.actionsTableView.reloadData()
    }
}
