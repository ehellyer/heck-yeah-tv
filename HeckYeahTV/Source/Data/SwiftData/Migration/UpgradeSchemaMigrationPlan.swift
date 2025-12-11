//
//  UpgradeSchemaMigrationPlan.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

enum UpgradeSchemaMigrationPlan: SchemaMigrationPlan {
    
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self
        ]
    }
    
    static var stages: [MigrationStage] {
        []
    }
    
    //MARK: - Migration stages between versions below.
}
