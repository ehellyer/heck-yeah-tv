//
//  SwiftDataStackProvider.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/31/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
protocol SwiftDataStackProvider {
    
    /// Model Container.
    var container: ModelContainer { get }
    
    /// MainActor UI ModelContext.  Dev note: EJH - Autosave is disabled on this context in the data stack provider.
    var viewContext: ModelContext { get }
    
}
