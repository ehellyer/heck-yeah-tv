//
//  NavigationActivationView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/26/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NavigationActivationView: View {
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
            .focusable(true)
            .onTapGesture {
                show()
            }
#else
        content
            .highPriorityGesture(TapGesture().onEnded { show() })
#endif
    }
}

