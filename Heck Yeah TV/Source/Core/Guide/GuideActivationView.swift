//
//  GuideActivationView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/26/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideActivationView: View {
    @Environment(GuideStore.self) private var guideStore
    
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .modifier(ReactivationGestures {
                withAnimation { guideStore.isGuideVisible = true }
            })
    }
}

// Platform-aware gesture modifier
private struct ReactivationGestures: ViewModifier {
    let show: () -> Void
    
    func body(content: Content) -> some View {
#if os(tvOS)
        // tvOS: no DragGesture; tap is fine. Remote swipes handled via .onMoveCommand at container.
        content.highPriorityGesture(TapGesture().onEnded { show() })
        
#elseif os(macOS)
        // macOS: hover or click to reveal
        content
            .onHover { _ in show() }
            .highPriorityGesture(TapGesture().onEnded { show() })
        
#else
        // iOS (and Mac Catalyst): tap or drag anywhere to reveal
        content
            .highPriorityGesture(TapGesture().onEnded { show() })
            .simultaneousGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in show() }
            )
#endif
    }
}

