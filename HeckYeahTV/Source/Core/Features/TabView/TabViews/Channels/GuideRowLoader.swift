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
    
    private var isLoading: Bool = false
    private var task: Task<Void, Never>?
    
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    func load(channelId: ChannelId, context: ModelContext) {
        guard channel?.id != channelId, isLoading == false else { return }
        isLoading = true
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let chPredicate = #Predicate<IPTVChannel> { $0.id == channelId }
                var chDescriptor = FetchDescriptor<IPTVChannel>(predicate: chPredicate)
                chDescriptor.fetchLimit = 1
                let model = try context.fetch(chDescriptor).first
                
                await MainActor.run {
                    self.channel = model
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.channel = nil
                    self.isLoading = false
                }
            }
        }
    }
}

