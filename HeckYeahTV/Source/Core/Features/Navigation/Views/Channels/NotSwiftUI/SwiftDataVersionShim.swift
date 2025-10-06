//
//  SwiftDataVersionShim.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 10/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

private enum _SDStringKey: String { case inserted, updated, deleted }

private func _extractIDs(from ui: [AnyHashable: Any],
                         typed: AnyHashable,
                         fallback: _SDStringKey) -> Set<PersistentIdentifier> {
    
    if let s = ui[typed] as? Set<PersistentIdentifier> { return s }
    if let a = ui[typed] as? [PersistentIdentifier] { return Set(a) }

    if let s = ui[fallback.rawValue] as? Set<PersistentIdentifier> { return s }
    if let a = ui[fallback.rawValue] as? [PersistentIdentifier] { return Set(a) }

    // Defensive: sometimes bridging gives NSSet/NSArray
    if let ns = ui[fallback.rawValue] as? NSSet,
       let asIDs = ns.allObjects as? [PersistentIdentifier] { return Set(asIDs) }

    return []
}

extension Notification {
    var sdChanges: (inserted: Set<PersistentIdentifier>,
                    updated:  Set<PersistentIdentifier>,
                    deleted:  Set<PersistentIdentifier>) {
        let ui = userInfo ?? [:]
        let inserted = _extractIDs(from: ui,
                                   typed: ModelContext.NotificationKey.insertedIdentifiers,
                                   fallback: .inserted)
        let updated  = _extractIDs(from: ui,
                                   typed: ModelContext.NotificationKey.updatedIdentifiers,
                                   fallback: .updated)
        let deleted  = _extractIDs(from: ui,
                                   typed: ModelContext.NotificationKey.deletedIdentifiers,
                                   fallback: .deleted)
        return (inserted, updated, deleted)
    }
}
