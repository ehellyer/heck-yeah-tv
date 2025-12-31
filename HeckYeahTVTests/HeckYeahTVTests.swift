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
        let mockData = MockSwiftDataStack()
        let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
        let totalCount = swiftDataController.channelBundleMap.mapCount
        #expect(totalCount != 0)
    }

//    @Test @MainActor func testGuideFetch() async throws {
//        let controller = HomeRunChannelGuideController()
//        let result = try await controller.channelGuideFetch(deviceAuth: "IPcDQ65-Fm8BuirRPSO59Gk5",
//                                                            start: nil,
//                                                            duration: 2,
//                                                            channelNumber: "8.4")
//        #expect(result.count != 0)
//        
//    }
    
}
