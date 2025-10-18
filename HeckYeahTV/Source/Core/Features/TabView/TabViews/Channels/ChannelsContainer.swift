//
//  ChannelsContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelsContainer: View {
    
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState
    var channelMap: IPTVChannelMap
    @State private var updateScrollViewFocus: Bool = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ShowFavorites(focus: $focus, appState: $appState, focusRedirectAction: { updateScrollViewFocus = true })
#if os(tvOS)
                .focusSection()
#endif
            GuideView(focus: $focus, appState: $appState, channelMap: channelMap, updateScrollViewFocus: $updateScrollViewFocus)
#if os(tvOS)
                .focusSection()
#endif
        }
    }
}

