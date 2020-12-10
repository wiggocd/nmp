//
//  ProcessPipe.swift
//  nmp
//
//  Created by Kate Wiggins on 10/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation

public typealias PipeProcessTerminationHandler = ((_ out: String, _ status: OSStatus) -> Void)
typealias ProcessTerminationHandler = ((_ process: Process) -> Void)

protocol Pipeable {
    func pipe(_ process: Self, _ complete: PipeProcessTerminationHandler) -> Self
}

infix operator |
