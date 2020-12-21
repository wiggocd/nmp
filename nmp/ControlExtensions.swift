//
//  Extensions.swift
//  nmp
//
//  Created by C. Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

extension NSSlider {
    func reset() {
        self.doubleValue = self.minValue
    }
}


