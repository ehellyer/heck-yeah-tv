//
//  ChannelBundleDevice.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/12/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class ChannelBundleDevice: JSONSerializable {
        
        init(bundle: ChannelBundle,
             device: HomeRunDevice) {
            self.bundle = bundle
            self.device = device
        }
        
        /// Relationship to the ChannelBundle - required for this join entry to exist
        @Relationship(deleteRule: .nullify, inverse: \ChannelBundle.deviceAssociations)
        var bundle: ChannelBundle
        
        /// Relationship to the HomeRunDevice - required for this join entry to exist
        @Relationship(deleteRule: .nullify, inverse: \HomeRunDevice.bundleAssociations)
        var device: HomeRunDevice
        
        // MARK: - JSONSerializable Implementation (added for mock data)
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case bundle
            case device
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(bundle, forKey: .bundle)
            try container.encode(device, forKey: .device)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.bundle = try container.decode(ChannelBundle.self, forKey: .bundle)
            self.device = try container.decode(HomeRunDevice.self, forKey: .device)
        }
    }
}
