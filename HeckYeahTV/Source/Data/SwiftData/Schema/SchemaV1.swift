//
//  SchemaV1.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftData

enum SchemaV1: VersionedSchema {
    
// Version 0.0.0: The self-destruct sequence. Set this and the store goes "poof" on startup. 💥
// It's like a phoenix, except instead of rising from ashes, it just... starts over with a blank slate.
//#warning("INCREMENT version 0.0.0 prior to release, else the SwiftData store will be deleted and recreated on every application cold start.")
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            ChannelBundle.self,
            ChannelProgram.self,
            HomeRunDevice.self,
            ProgramCategory.self,
            Channel.self,
            Country.self,
            Favorite.self,
            SchemaVersion.self
        ]
    }
}
