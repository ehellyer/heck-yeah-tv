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
    
    var number: String? {
        if channel == nil {
            // "Placeholder" is used for .redacted(reason: .placeholder) modifier.
            return "Placeholder"
        } else if let _number = channel?.number {
            return _number
        } else {
            return nil
        }
    }
    
    var qualityImage: Image? {
        if channel == nil {
            // "PH" is used for .redacted(reason: .placeholder) modifier.
            return .init(systemName: "questionmark.square")
        } else {
            guard let image = channel?.quality.image else {
                return nil
            }
            return image.asImage
        }
    }
    
//    var qualityView: StreamQualityRepresentableView? {
//        guard let q = channel?.quality else {
//            return nil
//        }
//        return StreamQualityRepresentableView(streamQuality: q)
//    }
    
    var noSubText: Bool {
        return channel?.number == nil
        && (channel?.quality ?? .unknown) == .unknown
        && (channel?.hasDRM ?? false) == false
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let _number = number {
                Text(_number)
                    .font(Font(AppStyle.Fonts.subtitleFont))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            if let _qualityImage = qualityImage {
                _qualityImage
            }

//            if let c = channel, c.quality != .unknown, let _qualityImage = qualityView {
//                _qualityImage
//            }
            
//TODO: EJH - Need to create a dynamic image cache similar to the quality image.
//            if channel?.hasDRM == true {
//                Text("DRM")
//                    .font(Font(AppStyle.Fonts.streamQualityFont))
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//                    .padding(.horizontal, 2)
//                    .padding(.vertical, 0)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 3)
//                            .stroke(.guideForegroundNoFocus,
//                                    lineWidth: redactionReasons.contains(.placeholder) ? 0 : 1)
//                    )
//            }
            
            // If there is no subtext, we want a nbsp to size the label vertically so it does not collapse to zero,
            // but is also still responsive to dynamic text size.
            if noSubText {
                Text(" ")
                    .font(.caption2)
                    .foregroundStyle(.guideForegroundNoFocus)
                    .lineLimit(1)
            }
        }
    }
}

#Preview("GuideSubTitleView - loads from Mock SwiftData") {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    let mockData = MockDataPersistence(appState: appState)
    appState.selectedChannel = mockData.channels[0].id
    appState.selectedChannel = mockData.channels[1].id
    appState.selectedChannel = mockData.channels[2].id
    appState.selectedChannel = mockData.channels[3].id
    appState.selectedChannel = mockData.channels[4].id
    
    return GuideSubTitleView(channel: mockData.channels[2])
}
