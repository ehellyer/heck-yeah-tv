//
//  HeckYeahTVTests.swift
//  Heck Yeah TVTests
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Testing
import SwiftData
import CryptoKit
import Hellfire

@testable import HeckYeahTV

@MainActor
struct HeckYeahTVTests {

//    var swiftDataStack = SwiftDataStack.shared
//        
//    var fetchChannelProgramsDescriptor: FetchDescriptor<ChannelProgram> {
//        FetchDescriptor<ChannelProgram>(
//            sortBy: [
//                SortDescriptor(\.channelId),
//                SortDescriptor(\.startTime)
//            ]
//        )
//    }
    
    @Test func lastGuideFetch() async throws {
//        var appState: AppStateProvider = SharedAppState.shared
//        let currentState = appState.dateLastHomeRunChannelProgramFetch
//        
//        let testDate = Date()
//        appState.dateLastHomeRunChannelProgramFetch = testDate
//        #expect(appState.dateLastHomeRunChannelProgramFetch == testDate)
//        
//        //Return previous state
//        appState.dateLastHomeRunChannelProgramFetch = currentState
    }
    
    @Test @MainActor func example() async throws {
//        let swiftDataController = MockSwiftDataController()
//        let totalCount = swiftDataController.channelBundleMap.mapCount
//        #expect(totalCount != 0)
    }

    @Test @MainActor func testGuideFetch() async throws {
        
//        let modelContext = self.swiftDataStack.viewContext
//        let descriptor = self.fetchChannelProgramsDescriptor
//        let fetchedPrograms: [ChannelProgram] = try modelContext.fetch(descriptor)
//
//        let jsonString = try fetchedPrograms.toJSONString()
//        
//        
//        #expect(jsonString.isEmpty == false)
    }
    
    @Test func testHDHomeRunProbeUnicast() async throws {
        print("=== Starting HDHomeRun Probe Unicast Test ===")
        let probe = HDHomeRunProbe()
        
        do {
            let devices: [HDHomeRunProbe.DiscoveredDevice] = try await probe.discoverDevices(targetIP: "192.168.78.220")
            print("✅ Found \(devices.count) device(s)")
            
            for device in devices {
                print("Device ID: \(device.deviceID)")
                print("Device Type: \(device.deviceType)")
                print("Base URL: \(device.baseURL)")
                print("IP Address: \(device.ipAddress)")
            }
            
            #expect(devices.count > 0, "Expected to find at least one device")
        } catch {
            print("❌ Error: \(error)")
            throw error
        }
    }
    
    @Test func testHDHomeRunProbeBroadcast() async throws {
        print("=== Starting HDHomeRun Probe Broadcast Test ===")
        let probe = HDHomeRunProbe()
        
        do {
            let devices: [HDHomeRunProbe.DiscoveredDevice] = try await probe.discoverDevices()
            print("✅ Found \(devices.count) device(s) via broadcast")
            
            for device in devices {
                print("Device ID: \(device.deviceID)")
                print("Device Type: \(device.deviceType)")
                print("Base URL: \(device.baseURL)")
                print("IP Address: \(device.ipAddress)")
            }
            
            #expect(devices.count > 0, "Expected to find at least one device")
        } catch {
            print("❌ Error: \(error)")
            throw error
        }
    }
    
}
