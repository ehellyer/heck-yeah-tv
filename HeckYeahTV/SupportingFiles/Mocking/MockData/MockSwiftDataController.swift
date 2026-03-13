//
//  MockSwiftDataController.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Observation

@MainActor @Observable
final class MockSwiftDataController: BaseSwiftDataController {
    
    //MARK: - MockSwiftDataController lifecycle

    init() {
        //Always use mock data stack for mock data so we don't accidentally persist the mock data to SQLite database.
        let stack = MockSwiftDataStack.shared
        super.init(viewContext: stack.viewContext, container: stack.container)
        self.selectedCountry = "US"
    }
}
