//
//  SchemaVersion.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/1/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

// Note: In the current design, only existence of this model with the property version is detected to determine if it is a legacy store (pre-schema versioning).
// Nothing is currently being written to this model in the persistent store.

// Added as extension to HeckYeahSchema so the model is always in current active Schema.
extension HeckYeahSchema {
    
    @Model final class SchemaVersion {
        #Index<SchemaVersion>([\.id])
        
        init() {
            self.id = UUID(uuidString: "fe7046c4-c15d-4e78-ba5b-50378a50c0b1")!
            self.version = HeckYeahSchema.versionIdentifier.description
        }
        
        @Attribute(.unique)
        var id: UUID
        
        /// Version of the current schema
        var version: String
    }
}
