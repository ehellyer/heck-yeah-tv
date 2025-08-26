//
//  PlatformRootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

struct PlatformRootView: View {
    @Binding var isReady: Bool
    
    var body: some View {
        BootGateView(isReady: $isReady) {
#if os(iOS)
            NavigationStack {
                RootView()
            }
#elseif os(tvOS)
            RootView()
                .focusEffectDisabled(true)
                .ignoresSafeArea()
#elseif os(macOS)
            RootView()
                .frame(minWidth: 900, minHeight: 507)
#else
            RootView()
#endif
        }
    }
}

#Preview {
    PlatformRootView(isReady: .constant(true))
}
