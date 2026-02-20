//
//  SchemaVersion.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/1/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

// Added as extension to HeckYeahSchema so the model is always in current active Schema, allowing the schema version to be read offline from the SQLite DB directly.
extension HeckYeahSchema {
    
    @Model final class SchemaVersion {
        #Index<SchemaVersion>([\.id])
        
        init() {
            self.id = UUID(uuidString: "fe7046c4-c15d-4e78-ba5b-50378a50c0b1")!
            self.version = HeckYeahSchema.versionIdentifier.description
        }
        
        /// Unique identifier for the only instance
        @Attribute(.unique)
        private(set) var id: UUID
        
        /// Version of the current schema
        private(set) var version: String
    }
}
