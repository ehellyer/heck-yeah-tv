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
    
    @Environment(\.modelContext) private var viewContext
    @StateObject private var loader = GuideRowLoader()
    
    var body: some View {
        Group {
            if let channel = loader.channel {
                // Reuse your existing GuideRow for the actual UI
                GuideRow(channel: channel, focus: $focus, appState: $appState)
                    .id(channel.id)
            } else {
                // Skeleton placeholder while loading
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
                .overlay(
                    // Simple shimmering/pulsing effect using phase animation
                    Color.clear
                        .modifier(Shimmer())
                )
                .id("channelId-\(channelId)")
            }
        }
        .onAppear {
            loader.load(channelId: channelId, context: viewContext)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

// Simple shimmer effect using SwiftUI phase animation
private struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(gradient: Gradient(stops: [
                    .init(color: .black.opacity(0.4), location: phase),
                    .init(color: .black, location: phase + 0.1),
                    .init(color: .black.opacity(0.4), location: phase + 0.2)
                ]), startPoint: .leading, endPoint: .trailing)
                .onAppear {
                    withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                        phase = 1.0
                    }
                }
            )
    }
}
