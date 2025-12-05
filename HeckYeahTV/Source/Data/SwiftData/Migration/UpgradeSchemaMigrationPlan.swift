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
    
    // Developer Note: V1, V2, V3 are pre-release schema changes.
    
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self,
            SchemaV3.self
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            migrateV1toV2,
            migrateV2toV3
        ]
    }
    
    private static var v1MigrationData: [ChannelId: V1MigrationData] = [:]

    static let migrateV1toV2 = MigrationStage.custom(fromVersion: SchemaV1.self,
                                                     toVersion: SchemaV2.self,
                                                     willMigrate: { context in
        
        logDebug("SwiftData: Migrating from SchemaV1 to SchemaV2 starting...")
        
        let descriptor = FetchDescriptor<SchemaV1.IPTVChannel>()
        let v1IPTVChannels: [SchemaV1.IPTVChannel] = try context.fetch(descriptor)
        
        try v1IPTVChannels.forEach {
            // Source.homeRunTuner(deviceId: "") will have the deviceId set correctly in a post migration step in the SwiftData Importer.
            let source: SchemaV2.ChannelSource = $0.source.migrateToV2()
            let sourceData = try source.toJSONData()
            Self.v1MigrationData[$0.id] = V1MigrationData(isFavorite: $0.isFavorite, source: sourceData)
        }
    },
                                                     didMigrate: { context in
        
        let v2IPTVChannels: [SchemaV2.IPTVChannel] = try context.fetch(FetchDescriptor<SchemaV2.IPTVChannel>())
        
        for channel in v2IPTVChannels {
            let sourceData: Data = v1MigrationData[channel.id]!.source
            channel.isFavorite = v1MigrationData[channel.id]!.isFavorite
            channel.source = try SchemaV2.ChannelSource.initialize(jsonData: sourceData)
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        logDebug("SwiftData: Migrating from SchemaV1 to SchemaV2 complete.")
    })
    
    static let migrateV2toV3 = MigrationStage.lightweight(fromVersion: SchemaV2.self,
                                                     toVersion: SchemaV3.self)
}
