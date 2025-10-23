//
//  ChannelsContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelsContainer: View {
    
    @FocusState.Binding var tabHasFocus: Bool
    @FocusState var focus: FocusTarget?
    @Binding var appState: SharedAppState
    
    @State private var scrollToSelectedAndFocus: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ShowFavorites(focus: $focus,
                          appState: $appState,
                          upSwipeRedirectAction: {
                withAnimation {
                    focus = nil
                    tabHasFocus = true
                }
            },
                          rightSwipeRedirectAction: {
                scrollToSelectedAndFocus = true
            })
#if os(tvOS)
                .focusSection()
#endif
            GuideView(focus: $focus, appState: $appState, scrollToSelectedAndFocus: $scrollToSelectedAndFocus)
#if os(tvOS)
                .focusSection()
#endif
        }
    }
}

