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
        
        init(version: String) {
            self.version = version
        }
        
        /// Version of the current schema
        var version: String
    }
}
