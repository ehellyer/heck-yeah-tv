//
//  Notification+SwiftDataChangeTracking.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 10/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

/// Because SwiftData's notification `userInfo` dictionary is about as friendly as a box of mixed cables.
/// This extension teaches `Notification` how to speak human (well, Swift developer human) when dealing
/// with SwiftData's `ModelContext.didSave` notifications.
///
/// Instead of digging through userInfo with string keys and optional unwrapping like it's 2010,
/// you can now just ask: "Hey notification, what changed?" and get a nice tuple back.
///
/// Example:
/// ```swift
/// let notifications = NotificationCenter.default.notifications(named: ModelContext.didSave)
/// for await notification in notifications {
///     let changes = notification.dataChanges
///     print("Inserted: \(changes.inserted.count)")
///     print("Updated: \(changes.updated.count)")
///     print("Deleted: \(changes.deleted.count)")
/// }
/// ```
extension Notification {
    
    /// Extracts the inserted, updated, and deleted persistent identifiers from a SwiftData notification.
    ///
    /// This is basically a fancy unpacking service for SwiftData's notification baggage.
    /// We try multiple ways to extract the data because Apple's APIs are like opening a surprise box —
    /// sometimes it's a `Set`, sometimes it's an `Array`, sometimes it's an `NSSet` because bridging
    /// thought it would be funny. We handle all the cases so you don't have to.
    ///
    /// - Returns: A tuple containing sets of identifiers for inserted, updated, and deleted objects.
    ///   If SwiftData didn't send us anything (rude!), we return empty sets. No optionals here —
    ///   we're civilized people.
    var dataChanges: (inserted: Set<PersistentIdentifier>,
                      updated: Set<PersistentIdentifier>,
                      deleted: Set<PersistentIdentifier>) {
        
        let inserted = extractIdentifiers(from: userInfo, dataChangeKey: .inserted)
        let updated  = extractIdentifiers(from: userInfo, dataChangeKey: .updated)
        let deleted  = extractIdentifiers(from: userInfo, dataChangeKey: .deleted)
        
        return (inserted, updated, deleted)
    }
}

/// The three flavors of SwiftData changes: things appeared, things changed, things vanished.
/// Kind of like your motivation during a long coding session.
private enum SwiftDataChangeTrackingKey: String {
    case inserted  // "Hello, I'm new here!" 👋
    case updated   // "I've changed, but I'm still me." 🔄
    case deleted   // "I must go, my people need me." 💨

    /// Maps our friendly enum cases to SwiftData's official notification keys.
    /// Because Apple likes to keep things formal with their `ModelContext.NotificationKey` type.
    var notificationKey: ModelContext.NotificationKey {
        switch self {
            case .inserted:
                return ModelContext.NotificationKey.insertedIdentifiers
                
            case .updated:
                return ModelContext.NotificationKey.updatedIdentifiers
                
            case .deleted:
                return ModelContext.NotificationKey.deletedIdentifiers
        }
    }
}

/// The identifier extraction workhorse. This function has seen some things.
///
/// It will try to extract persistent identifiers from the notification's userInfo in multiple ways
/// because SwiftData's notification format is like a box of chocolates — you never know what type
/// you're gonna get. Could be a `Set`, could be an `Array`, could be an `NSSet` because someone
/// at Apple thought Objective-C bridging was still cool.
///
/// We try them all, in order of likelihood, until we find the data or give up and return an empty set.
/// It's not the hero we wanted, but it's the hero we need.
///
/// - Parameters:
///   - userInfo: The notification's userInfo dictionary. Might be nil. Might be chaos. We handle it.
///   - dataChangeKey: Which kind of change we're looking for (inserted, updated, or deleted)
/// - Returns: A set of persistent identifiers, or an empty set if nothing was found. We never return nil
///   because we're not monsters.
private func extractIdentifiers(from userInfo: [AnyHashable: Any]?,
                                dataChangeKey: SwiftDataChangeTrackingKey) -> Set<PersistentIdentifier> {
    
    guard let userInfo else { return [] }
    
    // Attempt #1: Try the official notification key with a Set
    // This is what Apple's docs say it should be. Sometimes it actually is!
    if let identifiers = userInfo[dataChangeKey.notificationKey] as? Set<PersistentIdentifier> {
        return identifiers
    }
    
    // Attempt #2: Try the official notification key with an Array
    // Because why be consistent when you can keep developers on their toes?
    if let identifiers = userInfo[dataChangeKey.notificationKey] as? [PersistentIdentifier] {
        return Set(identifiers)
    }
    
    // Attempt #3: Try the string key with a Set
    // Fallback plan for when SwiftData is feeling old-school
    if let identifiers = userInfo[dataChangeKey.rawValue] as? Set<PersistentIdentifier> {
        return identifiers
    }
    
    // Attempt #4: Try the string key with an Array
    // Yes, we're trying everything. Yes, this is necessary. Don't ask.
    if let identifiers = userInfo[dataChangeKey.rawValue] as? [PersistentIdentifier] {
        return Set(identifiers)
    }

    // Attempt #5: The "Objective-C Bridging Decided to Join the Party" special
    // Sometimes NSSet shows up uninvited. We politely convert it to Swift and send it on its way.
    if let changeSet = userInfo[dataChangeKey.rawValue] as? NSSet, 
       let identifiers = changeSet.allObjects as? [PersistentIdentifier] {
        return Set(identifiers)
    }

    // We tried everything. Time to admit defeat and return an empty set.
    // At least we didn't crash! 🎉
    return []
}
