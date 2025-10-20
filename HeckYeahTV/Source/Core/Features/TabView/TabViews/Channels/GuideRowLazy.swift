//
//  GuideRowLazy.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/14/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct GuideRowLazy: View {
    let channelId: ChannelId
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState
    let isVisible: Bool
    
    @Environment(\.modelContext) private var viewContext
    @StateObject private var loader = GuideRowLoader()
    
    var body: some View {
        Group {
            if let channel = loader.channel {
                GuideRow(channel: channel,
                         focus: $focus,
                         appState: $appState)
            } else {
                HStack(spacing: 25) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .redacted(reason: .placeholder)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 300, height: 18)
                            .redacted(reason: .placeholder)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 220, height: 14)
                            .redacted(reason: .placeholder)
                    }
                    .frame(width: 400, alignment: .leading)
                    .padding(20)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
                        .redacted(reason: .placeholder)
                }
            }
        }
        .disabled(!isVisible)
        
        .onAppear {
            loader.load(channelId: channelId, context: viewContext)
        }
        
        .onDisappear {
            loader.cancel()
        }
    }
}

#Preview("GuideRowLazy - loads from SwiftData") {
    @Previewable @State var appState = SharedAppState.shared
    
    // Build an in-memory ModelContainer for previews
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: IPTVChannel.self, configurations: config)
    let context = ModelContext(container)
    
    // Seed a sample channel the loader can fetch
    let sampleId: ChannelId = "chan.preview.001"
    
    // Insert one IPTVChannel into the in-memory context
    do {
        let sampleChannel = IPTVChannel(
            id: "chan.preview.001",  //Change 001 to 002 to see the two effects
            sortHint: "0001",
            title: "Preview Channel",
            number: "Channel 121",
            url: URL(string: "https://example.com/stream.m3u8")!,
            logoURL: nil,
            quality: .fhd,
            hasDRM: false,
            source: .ipStream,
            isFavorite: true
        )
        context.insert(sampleChannel)
        try? context.save()
    }
    
    @FocusState var focus: FocusTarget?
    
    return GuideRowLazy(channelId: sampleId,
                        focus: $focus,
                        appState: $appState,
                        isVisible: true)
    .modelContainer(container)
    .environment(\.modelContext, context)
    .padding()
    .frame(width: 1200, height: 140)
}
