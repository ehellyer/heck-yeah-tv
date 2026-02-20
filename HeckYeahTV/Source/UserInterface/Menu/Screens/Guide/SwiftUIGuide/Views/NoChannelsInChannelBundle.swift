//
//  NoChannelsInChannelBundle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/3/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NoChannelsInChannelBundle: View {
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tv.slash")
                .font(.system(size: 56))
                .foregroundStyle(.guideForegroundNoFocus)
            Text("There are no channels in this bundle")
                .font(.headline)
                .foregroundStyle(.guideForegroundNoFocus)
            Text("Goto settings to create your channel bundle")
                .font(.subheadline)
                .foregroundStyle(.guideForegroundNoFocus)
            
            // Wrap button in a focusable region that spans the width
            HStack {
                Spacer()
                Button {
                    appState.selectedTab = .settings
                } label: {
                    Text("Settings")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
#if os(tvOS)
            .focusSection()
#endif
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 60)
        .background(Color.clear)
    }
}

#Preview {
    NoChannelsInChannelBundle()
}
