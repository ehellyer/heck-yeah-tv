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

            .frame(maxWidth: .infinity, maxHeight: .infinity) // fill parent
            .ignoresSafeArea()                                // fill safe areas too
            .accessibilityHidden(true)
#if os(tvOS)
            .focusable(true)
#endif
            .contentShape(Rectangle())
            .onTapGesture {
                print("Tap gesture received")
                withAnimation {
                    guideStore.isGuideVisible = true
                }
            }
    }
}

#Preview {
    let guideStore = GuideStore()
    TabActivationView().environment(guideStore)
}
