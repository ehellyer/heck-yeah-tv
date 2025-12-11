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
    
    @Binding var appState: AppStateProvider
    
    @Environment(\.modelContext) private var viewContext
    @FocusState private var isFocused: Bool
    
    @State private var scrollToSelectedAndFocus: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ShowFavorites(rightSwipeRedirectAction: {
                scrollToSelectedAndFocus = true
            })
            .focusSection()
            .focused($isFocused)

            GuideViewRepresentable(appState: $appState, isFocused: $isFocused)
                .focused($isFocused) // Bind to SwiftUI focus
                .onAppear {
                    isFocused = true
                }
        }
        .background(Color.clear)
    }
}
