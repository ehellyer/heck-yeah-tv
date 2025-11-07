//
//  GuideSubTitleView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideSubTitleView: View {
    
    @State var channel: IPTVChannel
    
    init(channel: IPTVChannel) {
        self.channel = channel
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let n = channel.number ?? (channel.quality.name == nil ? " " : nil) {
                Text(n)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            if let quality = channel.quality.name {
                Text(quality)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 0)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke())
            }
            if channel.hasDRM {
                Text("DRM")
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 0)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke())
            }
        }
    }
}

#if !os(tvOS)
#Preview("GuideSubTitleView - loads from Mock SwiftData") {
    @Previewable @State var appState = SharedAppState.shared
    
    let mockData = MockDataPersistence(appState: appState)
    
    HStack {
        GuideSubTitleView(channel: mockData.channels[1])
            .environment(\.modelContext, mockData.context)
        Spacer()
    }
}
#endif
