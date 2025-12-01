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
    }
}

extension SchemaV2 {
    
    enum ChannelSource: Hashable, Sendable, JSONSerializable {
        case ipStream
        case homeRunTuner(deviceId: HDHomeRunDeviceId)
    }
}
