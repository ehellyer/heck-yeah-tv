//
//  ChannelViewSubTitle.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelViewSubTitle: View {
    
    let channel: Channel?
    
    var number: String? {
        if channel == nil {
            // "Placeholder" is used for .redacted(reason: .placeholder) modifier.
            return "Placeholder"
        } else {
            return channel?.displayChannelNumber
        }
    }
    
    var qualityImage: Image? {
        if channel == nil {
            // "PH" is used for .redacted(reason: .placeholder) modifier.
            return .init(systemName: "questionmark.square")
        } else {
            return channel?.qualityImage
        }
    }
    
    var languageText: String? {
        if channel == nil {
            // "PLH" is used for .redacted(reason: .placeholder) modifier.
            return "PLH"
        }
        return channel?.languageText
    }
    
    var noSubText: Bool {
        return channel?.noSubText ?? true
    }
    
    var body: some View {
        HStack(spacing: 8) {
            
            if let _number = number {
                Text(_number)
                    .font(AppStyle.Fonts.gridRowFont)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            if let _qualityImage = qualityImage {
                _qualityImage
            }
            
            if let _languageText = languageText {
                Text(_languageText)
                    .font(AppStyle.Fonts.gridRowFont)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            if let countryFlag = channel?.countryFlag {
                countryFlag
                    .resizable()
                    .frame(width: AppStyle.ChannelView.countryFlagSize.width,
                           height: AppStyle.ChannelView.countryFlagSize.height) // ~2:3 aspect ratio
            }
            
            // If there is no subtext, we want a nbsp to size the label vertically so it
            // does not collapse to zero, but still remains responsive to dynamic text size.
            if noSubText {
                Text(nbsp)
                    .font(AppStyle.Fonts.gridRowFont)
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
    
    let channel = swiftDataController.channel(for: swiftDataController.channelBundleMap.channelIds[7])
    
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
