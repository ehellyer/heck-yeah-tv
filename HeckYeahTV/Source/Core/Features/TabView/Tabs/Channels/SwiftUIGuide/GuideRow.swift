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
    let cornerRadius: CGFloat = 20

    @State var channel: IPTVChannel?
    @Binding var appState: AppStateProvider
    @State private var rowWidth: CGFloat = 800 // Default, will update dynamically

    private func isHorizontallyCompact(width: CGFloat) -> Bool {
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

        HStack(alignment: .center, spacing: 10) {
            Button {
                channel?.isFavorite.toggle()
                try? channel?.modelContext?.save()
            } label: {
                Image(systemName: channel?.isFavorite == true ? "star.fill" : "star")
                    .scaleEffect(1.2)
                    .foregroundStyle(channel?.isFavorite == true ? Color.yellow : Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }
            .buttonStyle(.borderless)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isPlaying ? .guideSelectedChannelBackground : .guideBackgroundNoFocus)
            )

            Button {
                appState.selectedChannel = channel?.id
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel?.title ?? "Placeholder")
                        .font(.headline)
                        .foregroundStyle(.guideForegroundNoFocus)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    GuideSubTitleView(channel: channel)
                }
                .padding(.horizontal, internalHzPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.clear)
            }
            .buttonStyle(.borderless)
            .frame(width: !compact ? 220 : nil)
            .frame(maxWidth: compact ? .infinity : nil)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isPlaying ? .guideSelectedChannelBackground : .guideBackgroundNoFocus)
            )

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
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isPlaying ? .guideSelectedChannelBackground : .guideBackgroundNoFocus)
                )
                .buttonStyle(.borderless)
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

#if !os(tvOS)
#Preview("GuideRow - loads from Mock SwiftData") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    let mockData = MockDataPersistence(appState: appState)
    GuideRow(channel: mockData.channels[2], appState: $appState)
        //.redacted(reason: .placeholder)
        .onAppear {
            appState.selectedChannel = mockData.channels[2].id
        }
}
#endif

