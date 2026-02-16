//
//  ModelContext+Extension.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/15/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData

extension ModelContext {
    
    /// Saves the context only if there are pending changes because calling `save()` on a context
    /// with nothing to save is perfectly legal, but also perfectly pointless. Like filing an expense
    /// report for zero dollars. Technically allowed, spiritually hollow.
    ///
    /// Under the hood, SQLite uses a Write Ahead Log (WAL) to stage changes before committing them.
    /// Every unnecessary `save()` writes a WAL frame, and WAL frames stack up until a checkpoint
    /// can truncate the file. Checkpointing requires *all* readers to have closed their transactions,
    /// so the fewer gratuitous writes you make, the better your odds of the WAL actually shrinking.
    ///
    /// TL;DR: Only save when you have something to save. Your SSD will thank you.
    ///
    /// - Throws: Any error from `ModelContext.save()` if the save fails.
    func saveChangesIfNeeded() throws {
        if self.hasChanges {
            try self.save()
        }
    }
}
