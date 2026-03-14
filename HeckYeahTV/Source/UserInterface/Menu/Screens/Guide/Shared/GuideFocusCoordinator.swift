//
//  GuideFocusCoordinator.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/14/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Observation

/// Coordinates focus between UIKit GuideViewController and SwiftUI ShowFavorites button
@MainActor
@Observable
final class GuideFocusCoordinator {
    
    /// When true, triggers focus to move to ShowFavorites button
    var shouldFocusShowFavorites: Bool = false
    
    /// Request focus to move to ShowFavorites button
    func requestFocusOnShowFavorites() {
        shouldFocusShowFavorites = true
        
        // Reset after a short delay to allow for re-triggering
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            shouldFocusShowFavorites = false
        }
    }
}
