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
            
            let logoWidth = AppStyle.ChannelView.logoSize.width
            let logoHeight = AppStyle.ChannelView.logoSize.height
            LoadImageAsync(url: channel?.logoURL,
                           defaultImage: Image(systemName: "tv.circle.fill"),
                           showProgressView: true)
            .frame(width: logoWidth, height: logoHeight)
            .tint(Color.guideForegroundNoFocus)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(channel?.title ?? "PlaceholderSizingText")
                    .font(.title3.bold())
                    .foregroundStyle(Color.guideForegroundNoFocus)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                ChannelViewSubTitle(channel: channel)
            }
        }
        .padding(.horizontal, AppStyle.ChannelView.internalHorizontalPadding)
    }
}

#Preview {
    
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"
    let channel = try! swiftDataController.channel(for: channelId)
    
    return ChannelName(channel: channel)
}
