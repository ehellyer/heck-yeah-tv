//
//  SwiftDataChangeTracking.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 10/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

private enum SwiftDataTrackingKey: String {
    case inserted, updated, deleted

    var notificationKey: ModelContext.NotificationKey {
        switch self {
            case .inserted: return ModelContext.NotificationKey.insertedIdentifiers
            case .updated: return ModelContext.NotificationKey.updatedIdentifiers
            case .deleted: return ModelContext.NotificationKey.deletedIdentifiers
        }
    }
}

private func extractIdentifiers(from userInfo: [AnyHashable: Any]?,
                                dataChangeKey: SwiftDataTrackingKey) -> Set<PersistentIdentifier> {
    
    guard let userInfo else { return [] }
    
    // Try Notification Key Identifiers
    if let identifiers = userInfo[dataChangeKey.notificationKey] as? Set<PersistentIdentifier> {
        return identifiers
    }
    if let identifiers = userInfo[dataChangeKey.notificationKey] as? [PersistentIdentifier] {
        return Set(identifiers)
    }
    
    // Try Fallback Key Identifiers
    if let identifiers = userInfo[dataChangeKey.rawValue] as? Set<PersistentIdentifier> {
        return identifiers
    }
    if let identifiers = userInfo[dataChangeKey.rawValue] as? [PersistentIdentifier] {
        return Set(identifiers)
    }

    // Try Defensive Fallback Key Identifiers - Sometimes bridging gives NSSet/NSArray
    if let changeSet = userInfo[dataChangeKey.rawValue] as? NSSet, let identifiers = changeSet.allObjects as? [PersistentIdentifier] {
        return Set(identifiers)
    }

    return []
}

extension Notification {
    var dataChanges: (inserted: Set<PersistentIdentifier>,
                      updated: Set<PersistentIdentifier>,
                      deleted: Set<PersistentIdentifier>) {
       
        let inserted = extractIdentifiers(from: userInfo, dataChangeKey: .inserted)
        let updated  = extractIdentifiers(from: userInfo, dataChangeKey: .updated)
        let deleted  = extractIdentifiers(from: userInfo, dataChangeKey: .deleted)
        
        return (inserted, updated, deleted)
    }
}
