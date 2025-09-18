//
//  TabActivationView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/26/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct TabActivationView: View {
    @Environment(GuideStore.self) private var guideStore
    
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
#if os(tvOS)
            .focusable(true)
            .onTapGesture {
                withAnimation {
                    guideStore.isGuideVisible = true
                }
            }
#else
            .highPriorityGesture(TapGesture().onEnded {
                withAnimation {
                    guideStore.isGuideVisible = true
                }
            })
#endif
    }
}
