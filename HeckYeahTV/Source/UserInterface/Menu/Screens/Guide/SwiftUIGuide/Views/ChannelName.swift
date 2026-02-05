//
//  ChannelName.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/15/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelName: View {
    
    let channel: Channel?
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 20) {
            
            let logoFrame = AppStyle.ChannelView.logoFrame
            LoadImageAsync(url: channel?.logoURL,
                           defaultImage: Image(systemName: "tv.circle.fill"),
                           showProgressView: true)
            .frame(width: logoFrame, height: logoFrame)
            .tint(.gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(channel?.title ?? "PlaceholderSizingText")
                    .font(AppStyle.Fonts.gridRowFont.bold())
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                ChannelViewSubTitle(channel: channel)
            }
        }
        .padding(.horizontal, AppStyle.ChannelView.internalHorizontalPadding)
    }
}

#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController

    let channelId = swiftDataController.channelBundleMap.channelIds[1]
    let channel = try! swiftDataController.channel(for: channelId)

    return ChannelName(channel: channel)
}
