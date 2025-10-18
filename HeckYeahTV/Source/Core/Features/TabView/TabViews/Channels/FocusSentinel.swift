//
//  FocusSentinel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct FocusSentinel: View {
    
    @FocusState.Binding var focus: FocusTarget?
    var action: (() -> Void)?
    
    @State private var sentinelFocusId: FocusTarget = FocusTarget.guide(channelId: String.randomString(length: 5), col: Int.random(in: -100 ... -10))
    @State private var redirecting = false
    
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .focusable(true)
            .focusEffectDisabled(true)
            .accessibilityHidden(true)
            .allowsHitTesting(true)
            .focused($focus, equals: sentinelFocusId)
            .onChange(of: focus) { _, newFocus in
                // Did this view get focus?
                guard newFocus == sentinelFocusId, !redirecting else { return }
                redirecting = true
                withAnimation {
                    action?()
                    redirecting = false
                }
            }
    }
}
