//
//  GuideView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//

import SwiftUI

struct GuideView: View {
    @StateObject var store = GuideStore()
    
    var body: some View {
        NavigationView {
            List(store.visibleChannels) { channel in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.title)
                            .font(.headline)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            if let n = channel.number { Text(n).font(.caption).foregroundStyle(.secondary) }
                            if channel.isHD { Text("HD").font(.caption2).padding(.horizontal, 4).padding(.vertical, 2).overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.4))) }
                            if channel.hasDRM { Text("DRM").font(.caption2).padding(.horizontal, 4).padding(.vertical, 2).overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.4))) }
                        }
                    }
                    Spacer()
                    Button {
                        store.toggleFavorite(channel)
                    } label: {
                        Image(systemName: store.isFavorite(channel) ? "star.fill" : "star")
                    }
                    .buttonStyle(.borderless)
                    
                    Button("Play") {
                        store.select(channel)
                        // kick off playback with channel.url
                        // e.g., player.play(url: channel.url)
                    }
                    
                }
            }
            .navigationTitle("Guide")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: store.showFavoritesOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .help("Toggle favorites filter")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Last") {
                        store.switchToLastChannel()
                    }
                    .disabled(store.lastPlayedId == nil)
                }
            }
            .onAppear {
                // Supply your arrays here
                // store.load(streams: tvgStreams, tuner: tunerChannels)
            }
            
            Text("Select a channel")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview() {
    GuideView()
}
