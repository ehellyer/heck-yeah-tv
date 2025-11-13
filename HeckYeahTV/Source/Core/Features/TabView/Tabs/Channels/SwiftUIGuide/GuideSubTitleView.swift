//
//  GuideSubTitleView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideSubTitleView: View {
    
    @Environment(\.redactionReasons) private var redactionReasons
    @State var channel: IPTVChannel?
    
    var number: String {
        if channel == nil {
            return "Placeholder"
        } else if let _number = channel?.number {
            let spacer = (channel?.quality.name != nil) ? " " : ""
            return _number + spacer
        } else {
            return ""
        }
    }
    
    var quality: String? {
        if channel == nil {
            return "PH"
        } else {
            return channel?.quality.name
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(number)
                .font(.caption)
                .foregroundStyle(.guideForegroundNoFocus)
                .lineLimit(1)
                .truncationMode(.tail)
            
            if let _quality = quality {
                Text(_quality)
                    .font(.caption2)
                    .foregroundStyle(.guideForegroundNoFocus)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.guideForegroundNoFocus,
                                    lineWidth: redactionReasons.contains(.placeholder) ? 0 : 1)
                    )
            }
            if channel?.hasDRM == true {
                Text("DRM")
                    .font(.caption2)
                    .foregroundStyle(.guideForegroundNoFocus)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.guideForegroundNoFocus,
                                    lineWidth: redactionReasons.contains(.placeholder) ? 0 : 1)
                    )
            }
        }
    }
}

#Preview("GuideSubTitleView - loads from Mock SwiftData") {
    @Previewable @State var appState: AppStateProvider =
    MockSharedAppState(isPlayerPaused: false,
                       selectedChannel: "chan.movies.001")
    
    let mockData = MockDataPersistence(appState: appState)
    
    HStack {
        Spacer()
        GuideSubTitleView(channel: mockData.channels[2])
        //.redacted(reason: .placeholder)
        Spacer()
    }
}
