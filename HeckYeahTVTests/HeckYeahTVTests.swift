//
//  HeckYeahTVTests.swift
//  Heck Yeah TVTests
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Testing
@testable import HeckYeahTV

struct HeckYeahTVTests {

    @Test @MainActor func example() async throws {
        let mockData = MockDataPersistence()
        let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
        
        let totalCount = swiftDataController.guideChannelMap.totalCount
        #expect(totalCount != 0)
    }

}
