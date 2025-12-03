//
//  SchemaV2.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftData

enum SchemaV2: VersionedSchema {
    
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            IPTVChannel.self,                       // Change to ChannelSource.  enum now has associated data for DeviceId.
            IPTVCountry.self,
            HDHomeRunServer.self,
            HeckYeahSchema.SchemaVersion.self       // New structure to detect if existing store is unversioned.
        ]
    }
}
