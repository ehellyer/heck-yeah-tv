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
    
    /// MainActor UI ModelContext.
    var viewContext: ModelContext { get }
}
