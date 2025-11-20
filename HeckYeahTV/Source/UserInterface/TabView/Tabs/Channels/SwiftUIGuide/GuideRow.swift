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
    
    // Focus tracking for each button
    @FocusState private var focusedButton: FocusedButton?
    
    private enum FocusedButton: Hashable {
        case favorite
        case channel
        case guide
    }
    
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
        
        HStack(alignment: .center, spacing: 0) {
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
            .focused($focusedButton, equals: .favorite)
            .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                              cornerRadius: cornerRadius,
                                              isFocused: focusedButton == .favorite))
            .padding(.trailing, 20)
            
            Button {
                appState.selectedChannel = channel?.id
            } label: {
                Group {
                    VStack(alignment: .leading, spacing: 10) {
                        // "Placeholder" is used for .redacted(reason: .placeholder) modifier.
                        Text(channel?.title ?? "Placeholder")
                            .font(Font(AppStyle.Fonts.titleFont))
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
            .frame(width: !compact ? 320 : nil)
            .frame(maxWidth: compact ? .infinity : nil)
            .frame(maxHeight: .infinity)
            .focused($focusedButton, equals: .channel)
            .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                              cornerRadius: cornerRadius,
                                              isFocused: focusedButton == .channel))
            .padding(.trailing, 20)
            
            if !compact {
                Button {
                    // No op
                } label: {
                    Text("No guide information")
                        .font(Font(AppStyle.Fonts.programTitleFont))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, internalHzPadding)
                        .padding(.vertical, internalVtPadding)
                        .background(Color.clear)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .disabled(true)
                .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                                  cornerRadius: cornerRadius,
                                                  isFocused: focusedButton == .channel))
            }
            
//            if compact {
//                Spacer()
//            }
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


#Preview("GuideRow - loads from Mock SwiftData") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    let mockData = MockDataPersistence(appState: appState)
    GuideRow(channel: mockData.channels[2], appState: $appState)
    //.redacted(reason: .placeholder)
        .onAppear {
            appState.selectedChannel = mockData.channels[1].id
        }
}
