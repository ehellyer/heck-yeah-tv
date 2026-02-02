//
//  ChannelsContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct ChannelsContainer: View {
    
    // Private
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @FocusState private var isFocused: Bool
    @State private var scrollToSelectedAndFocus: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ShowFavorites(rightSwipeRedirectAction: {
                scrollToSelectedAndFocus = true
            })
            .padding(.bottom, 10)
            
            GuideViewRepresentable(isFocused: $isFocused)
                .focused($isFocused) // Bind to SwiftUI focus
                .onAppear {
                    isFocused = true
                }
        }
        .background(Color.clear)
    }
}

#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        ChannelsContainer()
    }
}
