//
//  View+Analytics.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/17/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

extension View {
    /// Tracks when a screen appears
    ///
    /// Usage:
    /// ```
    /// var body: some View {
    ///     YourView()
    ///         .trackScreen("Settings")
    /// }
    /// ```
    func trackScreen(_ screenName: String) -> some View {
        modifier(ScreenTrackingModifier(screenName: screenName))
    }
}

private struct ScreenTrackingModifier: ViewModifier {
    let screenName: String
    @Injected(\.analytics) private var analytics
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                analytics.log(.screenViewed(screenName: screenName))
            }
    }
}
