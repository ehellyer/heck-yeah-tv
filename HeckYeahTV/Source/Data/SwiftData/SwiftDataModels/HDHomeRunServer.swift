//
//  HDHomeRunServer.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class HDHomeRunServer: JSONSerializable {
        #Index<HDHomeRunServer>([\.deviceId])
        
        init(deviceId: HDHomeRunDeviceId,
             friendlyName: String,
             modelNumber: String,
             firmwareName: String,
             firmwareVersion: String,
             deviceAuth: String,
             baseURL: URL,
             lineupURL: URL,
             tunerCount: Int,
             includeChannelLineUp: Bool) {
            self.deviceId = deviceId
            self.friendlyName = friendlyName
            self.modelNumber = modelNumber
            self.firmwareName = firmwareName
            self.firmwareVersion = firmwareVersion
            self.deviceAuth = deviceAuth
            self.baseURL = baseURL
            self.lineupURL = lineupURL
            self.tunerCount = tunerCount
            self.includeChannelLineUp = includeChannelLineUp
        }
        
        @Attribute(.unique)
        var deviceId: HDHomeRunDeviceId
        var friendlyName: String
        var modelNumber: String
        var firmwareName: String
        var firmwareVersion: String
        var deviceAuth: String
        var baseURL: URL
        var lineupURL: URL
        var tunerCount: Int
        var includeChannelLineUp: Bool
        
        // MARK: - JSONSerializable Implementation
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
            case includeChannelLineUp
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
            try container.encode(includeChannelLineUp, forKey: .includeChannelLineUp)
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
            self.includeChannelLineUp = try container.decode(Bool.self, forKey: .includeChannelLineUp)
        }
    }
}
