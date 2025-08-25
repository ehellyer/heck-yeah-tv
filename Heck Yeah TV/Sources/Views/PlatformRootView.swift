//
//  PlatformRootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/22/25.
//

import SwiftUI

struct PlatformRootView: View {
    @Binding var isReady: Bool
    
    var body: some View {
        BootGate(isReady: $isReady) {
#if os(iOS)
            NavigationStack {
                RootView(autoplay: true)
            }
#elseif os(tvOS)
            RootView(autoplay: true)
                .focusEffectDisabled(true)
                .ignoresSafeArea()
#elseif os(macOS)
            RootView(autoplay: true)
                .frame(minWidth: 900, minHeight: 507)
#else
            RootView(autoplay: true)
#endif
        }
    }
}
