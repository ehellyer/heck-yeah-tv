//
//  HomeRunDevice.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class HomeRunDevice: JSONSerializable {
        #Unique<HomeRunDevice>([\.deviceId])
        #Index<HomeRunDevice>([\.deviceId], [\.isEnabled, \.deviceId])
        
        init(deviceId: HDHomeRunDeviceId,
             friendlyName: String,
             modelNumber: String,
             firmwareName: String,
             firmwareVersion: String,
             deviceAuth: String,
             baseURL: URL,
             lineupURL: URL,
             tunerCount: Int,
             isEnabled: Bool) {
            self.deviceId = deviceId
            self.friendlyName = friendlyName
            self.modelNumber = modelNumber
            self.firmwareName = firmwareName
            self.firmwareVersion = firmwareVersion
            self.deviceAuth = deviceAuth
            self.baseURL = baseURL
            self.lineupURL = lineupURL
            self.tunerCount = tunerCount
            self.isEnabled = isEnabled
        }
        
        /// The HomeRun unique device identifier. e.g. "21BC22D88"
        var deviceId: HDHomeRunDeviceId
        
        /// The HomeRun display name for the device. e.g. "HDHomeRun FLEX 4K"
        var friendlyName: String
        
        /// The HomeRun model number.  e.g.  "HDFX-4K"
        var modelNumber: String
        
        /// The HomeRun firmware name. e.g. "hdhomerun_dvr_atsc3"
        var firmwareName: String
        
        /// The HomeRun firmware version. e.g. "20250815"
        var firmwareVersion: String
        
        /// The devices guide authorization string.  e.g. "fC5B4yXmTHYaiYecEOrFDWkY"
        var deviceAuth: String
        
        /// The devices base URL. e.g. "http://192.168.1.210"
        var baseURL: URL
        
        /// The URL for the devices channel lineup. e.g. "http://192.168.1.210/lineup.json"
        var lineupURL: URL
        
        /// The number of tuners available in this device.  This equates to the number of concurrent TV channels this device can serve.
        var tunerCount: Int
        
        /// A boolean to indicate if this device is enabled and available for use in the Heck Yeah TV application.
        var isEnabled: Bool
        
        // Relationship to bundle associations (cascade on delete to clean up join entries when device is deleted)
        @Relationship(deleteRule: .cascade)
        var bundleAssociations: [ChannelBundleDevice] = []
        
        // MARK: - JSONSerializable Implementation (added for mock data)
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case deviceId
            case friendlyName
            case modelNumber
            case firmwareName
            case firmwareVersion
            case deviceAuth
            case baseURL
            case lineupURL
            case tunerCount
            case isEnabled
            case bundleAssociations
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(deviceId, forKey: .deviceId)
            try container.encode(friendlyName, forKey: .friendlyName)
            try container.encode(modelNumber, forKey: .modelNumber)
            try container.encode(firmwareName, forKey: .firmwareName)
            try container.encode(firmwareVersion, forKey: .firmwareVersion)
            try container.encode(deviceAuth, forKey: .deviceAuth)
            try container.encode(baseURL, forKey: .baseURL)
            try container.encode(lineupURL, forKey: .lineupURL)
            try container.encode(tunerCount, forKey: .tunerCount)
            try container.encode(isEnabled, forKey: .isEnabled)
            try container.encodeIfPresent(bundleAssociations, forKey: .bundleAssociations)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.deviceId = try container.decode(HDHomeRunDeviceId.self, forKey: .deviceId)
            self.friendlyName = try container.decode(String.self, forKey: .friendlyName)
            self.modelNumber = try container.decode(String.self, forKey: .modelNumber)
            self.firmwareName = try container.decode(String.self, forKey: .firmwareName)
            self.firmwareVersion = try container.decode(String.self, forKey: .firmwareVersion)
            self.deviceAuth = try container.decode(String.self, forKey: .deviceAuth)
            self.baseURL = try container.decode(URL.self, forKey: .baseURL)
            self.lineupURL = try container.decode(URL.self, forKey: .lineupURL)
            self.tunerCount = try container.decode(Int.self, forKey: .tunerCount)
            self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
            self.bundleAssociations = try container.decodeIfPresent([ChannelBundleDevice].self, forKey: .bundleAssociations) ?? []
        }
    }
}

//extension HomeRunDevice {
//    
//    var isEnabled_Save: Bool {
//        get {
//            return isEnabled
//        }
//        set {
//            isEnabled = newValue
//            try? self.modelContext?.saveChangesIfNeeded()
//        }
//    }
//}
