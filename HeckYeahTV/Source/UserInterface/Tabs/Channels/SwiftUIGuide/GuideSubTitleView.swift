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
    let channel: IPTVChannel?
    
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
    
    var languagesText: String? {
        guard let languages = channel?.languages, !languages.isEmpty else {
            return nil
        }
        return languages.first?.uppercased() //.map { $0.uppercased() }.joined(separator: ", ")
    }
    
    var noSubText: Bool {
        return channel?.number == nil
        && (channel?.quality ?? .unknown) == .unknown
        && (channel?.hasDRM ?? false) == false
        && languagesText == nil
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if case .homeRunTuner = channel?.source, let _number = number {
                Text(_number)
                    .font(Font(AppStyle.Fonts.subtitleFont))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            if let _qualityImage = qualityImage {
                _qualityImage
            }
            
            if let _languagesText = languagesText {
                Text(_languagesText)
                    .font(Font(AppStyle.Fonts.subtitleFont))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            // If there is no subtext, we want a nbsp to size the label vertically so it does not collapse to zero,
            // but is also still responsive to dynamic text size.
            if noSubText {
                Text(nbsp)
                    .font(.caption2)
                    .foregroundStyle(.guideForegroundNoFocus)
                    .lineLimit(1)
            }
        }
        .geometryGroup()
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
    
    return GuideSubTitleView(channel: mockData.channels[1])
}
