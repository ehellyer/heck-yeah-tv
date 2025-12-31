//
//  ProgramsRowLoader.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
final class ProgramsRowLoader: ObservableObject {
    @Published var programs: [ChannelProgram]?
    
    private var task: Task<Void, Never>?
    
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    func load(channelId: ChannelId, context: ModelContext) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let predicate = #Predicate<ChannelProgram> { $0.channelId == channelId }
                let sortDescriptor = SortDescriptor<ChannelProgram>(\.startTime, order: .forward)
                let fetchDescriptor = FetchDescriptor<ChannelProgram>(predicate: predicate, sortBy: [sortDescriptor])
                let model = try context.fetch(fetchDescriptor)
                try Task.checkCancellation()
                await MainActor.run {
                    self.programs = model
                }
            } catch {
                await MainActor.run {
                    self.programs = nil
                }
            }
        }
    }
}
