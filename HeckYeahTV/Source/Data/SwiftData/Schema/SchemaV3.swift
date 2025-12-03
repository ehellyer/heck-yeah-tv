//
//  SchemaV3.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/1/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftData

enum SchemaV3: VersionedSchema {
    
    static let versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            IPTVChannel.self,                       // Updated to add new properties.     var country: CountryCode?, var categories: [CategoryId]
            IPTVCountry.self,
            HDHomeRunServer.self,
            HeckYeahSchema.SchemaVersion.self,
            IPTVCategory.self                       // New structure to hold categories.
        ]
    }
}

/*
 Developer Note:

 Country and Categories were added to IPTVChannel to add two more dimensions to the proposed filter criteria.
 
 Proposed filter Criteria for IPTVChannel list:
 -----------------------------------------
 1. Channel title
 2. IsFavorite
 3. Country
 4. Category

*/
