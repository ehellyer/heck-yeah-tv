//
//  GuideRow.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct GuideRow: View {
    let internalHzPadding: CGFloat = 15
    let internalVtPadding: CGFloat = 15
    let cornerRadius: CGFloat = 20
    
    @State var channel: IPTVChannel?
    @Binding var appState: AppStateProvider
    @State private var rowWidth: CGFloat = 800 // Default, will update dynamically
    
    private func isHorizontallyCompact(width: CGFloat) -> Bool {
        // Quick and dirty way to get this view to render correctly when used in Recents on AppleTV.  A better solution needs to be developed.
        if appState.deviceType == .appleTV {
            return true
        }
        return width < 600
    }
    
    private var isPlaying: Bool {
        guard let selectedChannelId = appState.selectedChannel else {
            return false
        }
        return selectedChannelId == channel?.id
    }
    
    var body: some View {
        let compact = isHorizontallyCompact(width: rowWidth)

        HStack(alignment: .center, spacing: 20) {
            Button {
                channel?.isFavorite.toggle()
                try? channel?.modelContext?.save()
            } label: {
                Image(systemName: channel?.isFavorite == true ? "star.fill" : "star")
                    .scaleEffect(1.2)
                    .foregroundStyle(channel?.isFavorite == true ? Color.yellow : Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
            .modifier(ButtonBorderStyleModifier(isBordered: appState.deviceType == .appleTV,
                                                isPlaying: isPlaying,
                                                cornerRadius: cornerRadius))

            Button {
                appState.selectedChannel = channel?.id
            } label: {
                Group {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel?.title ?? "Placeholder")
                            .font(.headline)
                            .foregroundStyle(.guideForegroundNoFocus)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        GuideSubTitleView(channel: channel)
                    }
                    .padding(.horizontal, internalHzPadding)
                    .padding(.vertical, internalVtPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.clear)
                }
            }
            .frame(width: !compact ? 220 : nil)
            .frame(maxWidth: compact ? .infinity : nil)
            .frame(maxHeight: .infinity)
            .modifier(ButtonBorderStyleModifier(isBordered: appState.deviceType == .appleTV,
                                                isPlaying: isPlaying,
                                                cornerRadius: cornerRadius))


            if !compact {
                Button {
                    // No op
                } label: {
                    Text("No guide information")
                        .foregroundStyle(.guideForegroundNoFocus)
                        .frame(maxHeight: .infinity)
                        .background(Color.clear)
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .modifier(ButtonBorderStyleModifier(isBordered: appState.deviceType == .appleTV,
                                                    isPlaying: isPlaying,
                                                    cornerRadius: cornerRadius))
                .disabled(true)
            }

            if compact {
                Spacer()
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { rowWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        if rowWidth != newWidth {
                            rowWidth = newWidth
                        }
                    }
            }
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ButtonBorderStyleModifier: ViewModifier {
    let isBordered: Bool
    let isPlaying: Bool
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        Group {
            if isBordered {
                content.buttonStyle(.bordered)
            } else {
                content.buttonStyle(.borderless)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(isPlaying ? .guideSelectedChannelBackground : .guideBackgroundNoFocus)
                    )
            }
        }
    }
}


#Preview("GuideRow - loads from Mock SwiftData") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    let mockData = MockDataPersistence(appState: appState)
    GuideRow(channel: mockData.channels[2], appState: $appState)
        //.redacted(reason: .placeholder)
        .onAppear {
            appState.selectedChannel = mockData.channels[2].id
        }
}

