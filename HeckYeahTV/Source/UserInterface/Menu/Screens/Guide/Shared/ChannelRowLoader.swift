//
//  ChannelRowLoader.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 10/14/25.
//  Copyright © 2025 Hellyer Multimedia.
//

import Foundation
import SwiftData

@MainActor
final class ChannelRowLoader: ObservableObject {
    @Published var channel: Channel?
    
    private var task: Task<Void, Never>?
    private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    func load(channelId: ChannelId) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                // Simulate loading delay in preview mode
                if PreviewDetector.isRunningInPreview {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                let channel = try swiftDataController.channel(for: channelId)
                try Task.checkCancellation()
                await MainActor.run {
                    self.channel = channel
                }
            } catch {
                await MainActor.run {
                    self.channel = nil
                }
            }
        }
    }
}
