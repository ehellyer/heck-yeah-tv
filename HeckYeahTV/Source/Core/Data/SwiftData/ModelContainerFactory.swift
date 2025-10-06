// ModelContainerFactory.swift
import SwiftData

enum ModelContainerFactory {
    static func makePersistent() throws -> ModelContainer {
        try ModelContainer(for: IPTVChannel.self)
    }
    
    static func makeInMemory() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: IPTVChannel.self, configurations: config)
    }
}
