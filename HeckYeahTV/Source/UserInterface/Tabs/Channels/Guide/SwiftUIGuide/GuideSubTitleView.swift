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
            if channel?.source == ChannelSourceType.homeRunTuner.rawValue, let _number = number {
                Text(_number)
                    .font(AppStyle.Fonts.gridRowFont)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            if let _qualityImage = qualityImage {
                _qualityImage
            }
            
            if let _languagesText = languagesText {
                Text(_languagesText)
                    .font(AppStyle.Fonts.gridRowFont)
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
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockDataPersistence()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController

    let channel = swiftDataController.fetchChannel(at: 7)
    
    return GuideSubTitleView(channel: channel)
        //.redacted(reason: .placeholder)
}
