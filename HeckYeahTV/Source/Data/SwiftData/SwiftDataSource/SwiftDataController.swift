//
//  SwiftDataController.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/9/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Observation

@MainActor @Observable
final class SwiftDataController: BaseSwiftDataController {

    //MARK: - SwiftDataController lifecycle
    
    init() {
        let stack = SwiftDataStack.shared
        super.init(viewContext: stack.viewContext, container: stack.container)
    }
}
