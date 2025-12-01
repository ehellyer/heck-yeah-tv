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
            SchemaV1.self,
            SchemaV2.self
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            migrateV1toV2
        ]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(fromVersion: SchemaV1.self,
                                                     toVersion: SchemaV2.self,
                                                     willMigrate: { context in
        
        logDebug("SwiftData: Migrating from SchemaV1 to SchemaV2 starting...")
        
        //let predicate = #Predicate<SchemaV1.IPTVChannel> { $0.isFavorite == true }
        let descriptor = FetchDescriptor<SchemaV1.IPTVChannel>()//(predicate: predicate)
        let v1IPTVChannels: [SchemaV1.IPTVChannel] = try context.fetch(descriptor)
        
        try v1IPTVChannels.forEach {
            // Source will get set correctly in a post migration step in the Importer.
            let source: SchemaV2.ChannelSource = (($0.source == SchemaV1.ChannelSource.ipStream) ? SchemaV2.ChannelSource.ipStream : SchemaV2.ChannelSource.homeRunTuner(deviceId: ""))
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
    
    private static var v1MigrationData: [ChannelId: V1MigrationData] = [:]
}
