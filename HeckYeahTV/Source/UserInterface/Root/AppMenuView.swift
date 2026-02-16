//
//  AppMenuView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/10/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct AppMenuView: View {

    var body: some View {
#if os(tvOS)
        // App Menu for tvOS
        MenuTabView()
            .background(.clear)
#elseif os(macOS)
        // App Menu for iOS/macOS
        MenuPickerView()
            .background(.clear)
#elseif os(iOS)
        MenuPickerView()
            .background(.clear)
            .overlay {
                CarouselOverlay()
            }
#endif
    }
}

#if os(iOS)
/// Renders the ChannelProgramsCarousel on top of the AppMenuView on iOS.
/// On tvOS and macOS the carousel is rendered as an overlay of MainAppContentView instead,
/// because the app menu is a subview of the main content rather than a fullScreenCover.
private struct CarouselOverlay: View {
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]

    var body: some View {
        if let channelProgram = appState.showProgramDetailCarousel {
            ChannelProgramsCarousel(channelProgram: channelProgram)
                .zIndex(10)
        }
    }
}
#endif
