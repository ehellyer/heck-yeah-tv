//
//  ChannelViewSubTitle.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelViewSubTitle: View {
    
    @Environment(\.redactionReasons) private var redactionReasons
    let channel: Channel?
    
    var number: String? {
        if channel == nil {
            // "Placeholder" is used for .redacted(reason: .placeholder) modifier.
            return "Placeholder"
        } else if channel?.source == ChannelSourceType.homeRunTuner.rawValue, let _number = channel?.number {
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
    
    var languageText: String? {
        if channel == nil {
            // "PLH" is used for .redacted(reason: .placeholder) modifier.
            return "PLH"
        }
        guard let languages = channel?.languages, !languages.isEmpty else {
            return nil
        }
        return languages.first?.uppercased() //.map { $0.uppercased() }.joined(separator: ", ")
    }
    
    var noSubText: Bool {
        return channel?.number == nil
        && (channel?.quality ?? .unknown) == .unknown
        && (channel?.hasDRM ?? false) == false
        && languageText == nil
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let _number = number {
                Text(_number)
                    .font(AppStyle.Fonts.gridRowFont)
                    .foregroundColor(.guideForegroundNoFocus)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            if let _qualityImage = qualityImage {
                _qualityImage
                    .foregroundColor(.guideForegroundNoFocus)
            }
            
            if let _languageText = languageText {
                Text(_languageText)
                    .font(AppStyle.Fonts.gridRowFont)
                    .foregroundColor(.guideForegroundNoFocus)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            // If there is no subtext, we want a nbsp to size the label vertically so it does not collapse to zero,
            // but is also still responsive to dynamic text size.
            if noSubText {
                Text(nbsp)
                    .font(AppStyle.Fonts.gridRowFont)
                    .foregroundStyle(.guideForegroundNoFocus)
                    .lineLimit(1)
            }
        }
    }
}

#Preview("ChannelSubTitleView") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController

    let channel = swiftDataController.previewOnly_fetchChannel(at: 7)

    return TVPreviewView() {
        VStack {
            
            // Represents a loaded channel
            ChannelViewSubTitle(channel: channel)

            // Represents a loading channel
            ChannelViewSubTitle(channel: nil)
                .redacted(reason: .placeholder)
            
            Spacer()
        }
    }
}
