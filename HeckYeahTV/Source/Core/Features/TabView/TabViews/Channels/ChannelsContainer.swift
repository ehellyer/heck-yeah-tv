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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ShowFavorites(focus: $focus, appState: $appState, channelMap: channelMap)
            GuideView(focus: $focus, appState: $appState, channelMap: channelMap)
        }
    }
}

