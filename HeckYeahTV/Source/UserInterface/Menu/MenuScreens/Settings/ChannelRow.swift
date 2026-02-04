//
//  ChannelRow.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/3/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelRow: View {
    let channel: Channel
    let isInBundle: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack {
                ChannelName(channel: channel)
                
                Spacer()
                
                Image(systemName: isInBundle ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isInBundle ? .blue : .secondary)
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = swiftDataController.channelBundleMap.channelIds[0]
    let channel = try! swiftDataController.channel(for: channelId)
    
    return TVPreviewView() {
        ChannelRow(channel: channel,
                   isInBundle: false,
                   onToggle: {})
    }
}
