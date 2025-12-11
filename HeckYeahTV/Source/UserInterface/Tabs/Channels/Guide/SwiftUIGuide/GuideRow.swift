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
    @State var hideGuideInfo: Bool = true
    @State private var rowWidth: CGFloat = 800 // Default, will update dynamically
    @State private var logoImage: Image = Image(systemName: "tv.circle.fill")
    @State private var imageLoadTask: Task<Void, Never>? = nil
    @State private var favorite: IPTVFavorite?
    
    @Environment(\.modelContext) private var modelContext
    
    private var isFavoriteChannel: Bool {
        return favorite?.isFavorite ?? false
    }
    
    @Injected(\.attachmentController)
    private var attachmentController: AttachmentController
    
    // Focus tracking for each button
    @FocusState private var focusedButton: FocusedButton?
    
    private enum FocusedButton: Hashable {
        case favorite
        case channel
        case guide
    }
    
    private func isHorizontallyCompact(width: CGFloat) -> Bool {
        // Behave as compact when showing recents view.  This prevents the guide info to the right.
        if hideGuideInfo {
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
    
    private func fetchOrCreateFavorite() {
        guard let channelId = channel?.id else { return }
        
        do {
            let predicate = #Predicate<IPTVFavorite> { $0.id == channelId }
            var descriptor = FetchDescriptor<IPTVFavorite>(predicate: predicate)
            descriptor.fetchLimit = 1
            
            if let existingFavorite = try modelContext.fetch(descriptor).first {
                favorite = existingFavorite
            } else {
                // Create a new favorite with isFavorite = false
                let newFavorite = IPTVFavorite(id: channelId, isFavorite: false)
                modelContext.insert(newFavorite)
                try modelContext.save()
                favorite = newFavorite
            }
        } catch {
            logError("Failed to fetch or create favorite for channelId: \(channelId) - \(error)")
        }
    }
    
    var body: some View {
        let compact = isHorizontallyCompact(width: rowWidth)
        
        HStack(alignment: .center, spacing: 0) {
            Button {
                if let fav = favorite {
                    fav.isFavorite.toggle()
                    do {
                        try modelContext.save()
                    } catch {
                        logError("Failed to save favorite state: \(error)")
                    }
                }
            } label: {
                Image(systemName: isFavoriteChannel ? "star.fill" : "star")
                    .scaleEffect(1.2)
                    .foregroundStyle(isFavoriteChannel ? Color.yellow : Color.white)
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
                    HStack(spacing: 15) {
                        
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .fixedSize(horizontal: true, vertical: true)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            // "Placeholder" is used for .redacted(reason: .placeholder) modifier.
                            Text(channel?.title ?? "Placeholder")
                                .font(Font(AppStyle.Fonts.titleFont))
                                .lineLimit(1)
                                .truncationMode(.tail)
                            GuideSubTitleView(channel: channel)
                        }
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
            .task(id: channel?.id) {
                updateLogoImage(for: channel)
            }
            
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
        .onAppear {
            fetchOrCreateFavorite()
        }
        .onChange(of: channel?.id) { _, _ in
            fetchOrCreateFavorite()
        }
    }
}

#Preview("GuideRow - loads from Mock SwiftData") {
//    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
//    let mockData = MockDataPersistence(appState: appState)
//    GuideRow(channel: mockData.channels[8],
//             appState: $appState)
//    //.redacted(reason: .placeholder)
//        .onAppear {
//            appState.selectedChannel = mockData.channels[7].id
//        }
}
