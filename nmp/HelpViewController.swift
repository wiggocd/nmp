//
//  HelpViewController.swift
//  nmp
//
//  Created by C. Wiggins on 11/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class HelpViewController: DefaultViewController {
    let application = Application.shared as? Application
    
    @IBOutlet weak var actionsTableView: NSTableView!
    
    let actionsTableItems = [
        ("Play/Pause", "Space"),
        ("Global Play/Pause", "(Fn)+⌘+F1"),
        ("Global Next Track", "(Fn)+⌘+F2"),
        ("Global Rewind", "(Fn)+⌘+F3")
    ]
    
    override func viewDidLoad() {
        actionsTableView.delegate = self
        actionsTableView.dataSource = self
        actionsTableView.reloadData()
    }
}
