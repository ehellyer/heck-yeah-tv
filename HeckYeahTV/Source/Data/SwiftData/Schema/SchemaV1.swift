//
//  SchemaV1.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftData

enum SchemaV1: VersionedSchema {
    
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            IPTVChannel.self,
            IPTVCountry.self,
            HDHomeRunServer.self,
            HeckYeahSchema.SchemaVersion.self
        ]
    }
}
