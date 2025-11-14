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
    let corner: CGFloat = 10
    let horizontalPadding: CGFloat = 15
    let verticalPadding: CGFloat = 15
    let cornerRadius: CGFloat = 20

    @State var channel: IPTVChannel?
    @Binding var appState: AppStateProvider

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
        GeometryReader { geometry in
            let compact = isHorizontallyCompact(width: geometry.size.width)

            HStack(alignment: .center, spacing: 0) {

                Button {
                    channel?.isFavorite.toggle()
                    try? channel?.modelContext?.save()
                } label: {
                    Image(systemName: channel?.isFavorite == true ? "star.fill" : "star")
                        .scaleEffect(1.5)
                        .foregroundStyle(channel?.isFavorite == true ? Color.yellow : Color.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.guideBackgroundNoFocus)
                )
                .padding(.leading, 10)

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
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: !compact ? 200 : nil)
                .frame(maxWidth: compact ? .infinity : nil)
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.guideBackgroundNoFocus)
                )
                .padding(.leading, 10)

                if !compact {
                    Button {
                        // No op
                    } label: {
                        Text("No guide information")
                            .foregroundStyle(.guideForegroundNoFocus)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.guideBackgroundNoFocus)
                    )
                    .disabled(true)
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                }

                if compact {
                    Spacer()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .background {
                if isPlaying {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(.guideSelectedChannelBackground)
                        .padding(.top, -4)
                        .padding(.bottom, -4)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: 70) // Or any fixed height you wish for the row
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

