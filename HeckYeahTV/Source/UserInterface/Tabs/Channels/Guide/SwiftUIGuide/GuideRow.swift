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
    let cornerRadius: CGFloat = AppStyle.cornerRadius
    
    @State var channel: IPTVChannel?
    @Binding var appState: AppStateProvider
    @State var hideGuideInfo: Bool
    @State private var rowWidth: CGFloat = 800 // Default, will update dynamically
    @State private var logoImage: Image = Image(systemName: "tv.circle.fill")
    @State private var imageLoadTask: Task<Void, Never>? = nil
    
    @Environment(\.modelContext) private var modelContext
    
    @Injected(\.attachmentController)
    private var attachmentController: AttachmentController

    @State private var swiftDataController: SwiftDataControllable = InjectedValues[\.swiftDataController]
    
    // Focus tracking for each button
    @FocusState private var focusedButton: FocusedButton?

    private enum FocusedButton: Hashable {
        case favorite
        case channel
        case guide
    }
    
    private var isFavoriteChannel: Bool {
        return channel?.favorite?.isFavorite ?? false
    }
    
    private var isPlaying: Bool {
        guard let selectedChannelId = appState.selectedChannel else {
            return false
        }
        return selectedChannelId == channel?.id
    }

    private func isHorizontallyCompact(width: CGFloat) -> Bool {
        // Behave as compact when showing recents view.  This prevents the guide info to the right.
        if hideGuideInfo {
            return true
        }
        return width < 600
    }
    
    private func updateLogoImage(for channel: IPTVChannel?) {
        let currentChannelId = channel?.id
        imageLoadTask?.cancel()
        imageLoadTask = Task {
            logoImage = Image(systemName: "tv.circle.fill")
            let image = try? await attachmentController.fetchImage(channel?.logoURL)
            guard !Task.isCancelled, channel?.id == currentChannelId, let image else {
                return
            }
            logoImage = image
        }
    }
    
    var body: some View {
        let compact = isHorizontallyCompact(width: rowWidth)
        
        HStack(alignment: .center, spacing: 15) {
            Button {
                guard let channel else { return }
                if channel.favorite != nil {
                    channel.favorite?.isFavorite.toggle()
                } else {
                    channel.favorite = IPTVFavorite(id: channel.id, isFavorite: true)
                }
            } label: {
                Image(systemName: isFavoriteChannel ? "star.fill" : "star")
#if os(tvOS)
                    .scaleEffect(1.2)
#else
                    .scaleEffect(1.5)
#endif
                    .foregroundStyle(isFavoriteChannel ? Color.yellow : Color.white)
                    .frame(width: 70)
                    .frame(maxHeight: .infinity)
            }
            .focused($focusedButton, equals: .favorite)
            .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                              cornerRadius: cornerRadius,
                                              isFocused: focusedButton == .favorite))
            
            Button {
                appState.selectedChannel = channel?.id
            } label: {
                Group {
                    HStack(alignment: .center, spacing: 20) {
                        
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        
#if os(tvOS)
                            .frame(width: 70, height: 70)
#else
                            .frame(width: 60, height: 60)
#endif

                        
                            .fixedSize(horizontal: true, vertical: false)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            // "Placeholder" is used for .redacted(reason: .placeholder) modifier.
                            Text(channel?.title ?? "Placeholder")
                                .font(AppStyle.Fonts.gridRowFont)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            GuideSubTitleView(channel: channel)
                        }
                    }
                    .padding(.horizontal, internalHzPadding)
                    //.padding(.vertical, internalVtPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(maxHeight: .infinity)
                    .background(Color.clear)
                }
            }

#if os(tvOS)
            .frame(minWidth: 470)
#else
            .frame(minWidth: 280)
#endif
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .focused($focusedButton, equals: .channel)
            .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                              cornerRadius: cornerRadius,
                                              isFocused: focusedButton == .channel))
            .task(id: channel?.id) {
                updateLogoImage(for: channel)
            }
            
            if !compact {
                Button {
                    // No op
                } label: {
                    Text("No guide information")
                        .font(AppStyle.Fonts.gridRowFont)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, internalHzPadding)
                        .padding(.vertical, internalVtPadding)
                        .background(Color.clear)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                .disabled(true)
                .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                                  cornerRadius: cornerRadius,
                                                  isFocused: focusedButton == .channel))
            }
        }
#if os(tvOS)
        .frame(height: 100)
#else
        .frame(height: 80)
#endif
        
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
    
    let swiftController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftController
    
    let channel = swiftController.fetchChannel(at: 8)
    let selectedChannelId = swiftController.guideChannelMap.map[0]
    
    
    return TVPreviewView() {
        GuideRow(channel: channel,
                 appState: $appState,
                 hideGuideInfo: false)
        //.redacted(reason: .placeholder)
        .onAppear {
            appState.selectedChannel = selectedChannelId
        }
    }
}
