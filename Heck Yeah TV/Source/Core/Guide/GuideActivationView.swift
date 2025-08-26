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
        content
            //.highPriorityGesture(TapGesture().onEnded { show() })
            .focusable(true)                 // must be in focus system
            //.onAppear { hasFocus = true }    // claim focus when overlay is hidden
            .onMoveCommand { _ in show() }   // remote swipe
            //.onSelect { show() }      // remote click
        
#elseif os(macOS)
        content
            .highPriorityGesture(TapGesture().onEnded { show() })
        
#else
        content
            .highPriorityGesture(TapGesture().onEnded { show() })
#endif
    }
}

