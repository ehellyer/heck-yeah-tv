//
//  Heck_Yeah_TVApp.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

//------------------------------------------------------------------------------------------------------------------------
//       __    __                      __              __      __                    __              ________  __     __
//      |  \  |  \                    |  \            |  \    /  \                  |  \            |        \|  \   |  \
//      | $$  | $$  ______    _______ | $$   __        \$$\  /  $$______    ______  | $$____         \$$$$$$$$| $$   | $$
//      | $$__| $$ /      \  /       \| $$  /  \        \$$\/  $$/      \  |      \ | $$    \          | $$   | $$   | $$
//      | $$    $$|  $$$$$$\|  $$$$$$$| $$_/  $$         \$$  $$|  $$$$$$\  \$$$$$$\| $$$$$$$\         | $$    \$$\ /  $$
//      | $$$$$$$$| $$    $$| $$      | $$   $$           \$$$$ | $$    $$ /      $$| $$  | $$         | $$     \$$\  $$
//      | $$  | $$| $$$$$$$$| $$_____ | $$$$$$\           | $$  | $$$$$$$$|  $$$$$$$| $$  | $$         | $$      \$$ $$
//      | $$  | $$ \$$     \ \$$     \| $$  \$$\          | $$   \$$     \ \$$    $$| $$  | $$         | $$       \$$$
//       \$$   \$$  \$$$$$$$  \$$$$$$$ \$$   \$$           \$$    \$$$$$$$  \$$$$$$$ \$$   \$$          \$$        \$
//
//------------------------------------------------------------------------------------------------------------------------

/// Creates a function for not (!).
let not = (!)

/// Non-breakable space
let nbsp = "\u{00a0}"

/// Returns the name of the object as a string.
func stringName<T>(_ object: T) -> String {
    return String(describing: type(of: object))
}

/// A value in nanoseconds representing 0.01s or 10ms.
///
/// This is the time to sleep before executing a task, providing a small delay for
/// the the task to be cancelled because it was replaced by a similar subsequent task.
let debounceNS: UInt64 = 10_000_000 //0.01 seconds

@main
struct Heck_Yeah_TVApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isBootComplete = false
    @State private var startupTask: Task<Void, Never>? = nil
    @State private var dataPersistence: DataPersistence = DataPersistence.shared
    
    var body: some Scene {
#if os(macOS)
        Window("Heck Yeah TV", id: "main") {
            content()
        }
#else
        WindowGroup {
            content()
        }
#endif
    }
    
    private func content() -> some View {
        RootView(isBootComplete: $isBootComplete)
            .task {
                startBootstrap()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    startupTask?.cancel()
                }
            }
            .modelContainer(dataPersistence.container)
            .modelContext(dataPersistence.viewContext)
    }
    
    private func startBootstrap() {
        // Always ensure app navigation starts off in the dismissed state when there is a selected channel. Else present the default tab in app navigation.  This prevents a black screen on first startup.
        let appState = SharedAppState.shared
        appState.showAppNavigation = (appState.selectedChannel == nil)

        startupTask?.cancel()
        startupTask = Task {
            
            let hdHomeRunController = HDHomeRunDiscoveryController()
            let iptvController: IPTVController = IPTVController()
            var summary = FetchSummary()
            
            let hdHomeRunSummary = await hdHomeRunController.bootStrapTunerChannelDiscovery()
            let iptvSummary = await iptvController.fetchAll()
            summary.mergeSummary(hdHomeRunSummary)
            summary.mergeSummary(iptvSummary)
            
            // TODO: Log summary for collection, analysis and diagnostics.
            if summary.failures.count > 0 {
                logError("\(summary.failures.count) failure(s) in bootstrap data fetch: \(summary.failures)")
            }
            
            let container = dataPersistence.container
            Task.detached(priority: .userInitiated) {
                let importer = Importer(container: container)
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        try await importer.importCountries(iptvController.countries)
                    }
                    group.addTask {
                        try await importer.importChannels(feeds: iptvController.feeds,
                                                          logos: iptvController.logos,
                                                          channels: iptvController.channels,
                                                          streams: iptvController.streams,
                                                          tunerChannels: hdHomeRunController.channels)
                    }
                    group.addTask {
                        try await importer.importTunerDevices(hdHomeRunController.devices)
                    }
                    group.addTask {
                        try await importer.importCategories(iptvController.categories)
                    }
                    try await group.waitForAll()
                }
                
                await MainActor.run {
                    // Update state variable that boot up processes are completed.
                    isBootComplete = true
                }
            }
        }
    }
}
