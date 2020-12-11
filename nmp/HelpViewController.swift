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
        ("Play/Pause", "(Fn)+Command+F1"),
        ("Next Track", "(Fn)+Command+F2"),
        ("Rewind", "(Fn)+Command+F3")
    ]
    
    override func viewDidLoad() {
        actionsTableView.delegate = self
        actionsTableView.dataSource = self
        actionsTableView.reloadData()
    }
}
