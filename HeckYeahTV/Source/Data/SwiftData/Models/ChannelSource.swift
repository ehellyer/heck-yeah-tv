//
//  ChannelSource.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData
import Hellfire

extension SchemaV1 {
    enum ChannelSource: String, Hashable, Sendable, JSONSerializable {
        case ipStream
        case homeRunTuner
        
        func migrateToV2() -> SchemaV2.ChannelSource {
            switch self {
                case .ipStream:
                    return .ipStream
                case .homeRunTuner:
                    return .homeRunTuner(deviceId: "")
            }
        }
    }
}

extension SchemaV2 {
    
    enum ChannelSource: Hashable, Sendable, JSONSerializable {
        case ipStream
        case homeRunTuner(deviceId: HDHomeRunDeviceId)
        
        func migrateToV3() -> SchemaV3.ChannelSource {
            switch self {
                case .ipStream:
                    return .ipStream
                case .homeRunTuner(deviceId: let deviceId):
                    return .homeRunTuner(deviceId: deviceId)
            }
        }
    }
}

extension SchemaV3 {
    
    enum ChannelSource: Hashable, Sendable, JSONSerializable {
        case ipStream
        case homeRunTuner(deviceId: HDHomeRunDeviceId)
    }
}
