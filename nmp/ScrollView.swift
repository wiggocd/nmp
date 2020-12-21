//
//  ScrollView.swift
//  nmp
//
//  Created by C. Wiggins on 21/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

class NonUserScrollableScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        return
    }
}
