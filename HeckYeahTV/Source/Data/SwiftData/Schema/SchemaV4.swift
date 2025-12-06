//
//  SchemaV4.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/6/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//



import SwiftData

enum SchemaV4: VersionedSchema {
    
    static let versionIdentifier = Schema.Version(4, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            IPTVChannel.self,                       // Updated to add new language property
            IPTVCountry.self,
            HDHomeRunServer.self,
            HeckYeahSchema.SchemaVersion.self,
            IPTVCategory.self
        ]
    }
}

/*
 Developer Note:

 \\ Languages was added to IPTVChannel
 
*/
