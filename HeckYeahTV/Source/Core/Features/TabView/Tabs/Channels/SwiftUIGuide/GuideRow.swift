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
    let backgroundColor: Color = Color.gray
    
    @State var channel: IPTVChannel?
    @Binding var appState: AppStateProvider
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var isPlaying: Bool {
        guard let selectedChannelId = appState.selectedChannel else {
            return false
        }
        return selectedChannelId == channel?.id
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {

                Button {
                    channel?.isFavorite.toggle()
                } label: {
                    Image(systemName: channel?.isFavorite == true ? "star.fill" : "star")
                        .foregroundStyle(Color.yellow)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 7.5)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: isLandscape ? (geometry.size.width * 0.2) : nil)
                .frame(maxWidth: isLandscape ? nil : .infinity)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                )
                .padding(.leading, 10)
                
                if (isLandscape) {
                    Button {
                        // No op
                    } label: {
                        Text("No guide information")
                            .foregroundStyle(.guideForegroundNoFocus)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundColor)
                    )
                    .disabled(true)
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                }
                
                if !isLandscape {
                    Spacer()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .background {
                if isPlaying {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Color.guideSelectedChannelBackground)
                        .padding(.top, -4)
                        .padding(.bottom, -4)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
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
