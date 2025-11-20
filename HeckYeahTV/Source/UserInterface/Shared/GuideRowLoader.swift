//
//  GuideRowLoader.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 10/14/25.
//  Copyright © 2025 Hellyer Multimedia.
//

import SwiftUI
import SwiftData

@MainActor
final class GuideRowLoader: ObservableObject {
    @Published var channel: IPTVChannel?
    
    private var task: Task<Void, Never>?
    
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    func load(channelId: ChannelId, context: ModelContext, isDebug: Bool = false) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                if isDebug {
                    try await Task.sleep(nanoseconds: 2_000_000_000) //Debug only
                }
                let chPredicate = #Predicate<IPTVChannel> { $0.id == channelId }
                var chDescriptor = FetchDescriptor<IPTVChannel>(predicate: chPredicate)
                chDescriptor.fetchLimit = 1
                let model = try context.fetch(chDescriptor).first
                try Task.checkCancellation()
                await MainActor.run {
                    self.channel = model
                }
            } catch {
                await MainActor.run {
                    self.channel = nil
                }
            }
        }
    }
}
