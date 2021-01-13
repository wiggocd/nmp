//
//  ArrayExtensions.swift
//  nmp
//
//  Created by C. Wiggins on 22/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation

extension Array {
    func subrange(bounds: Range<Int>) -> [Any] {
        var subrange: [Any] = []
        for i in bounds {
            if i >= 0 && i < self.count - 1 {
                subrange.append(self[i])
            }
        }
        return subrange
    }
}
