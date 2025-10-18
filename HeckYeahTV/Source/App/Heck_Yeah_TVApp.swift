//
//  Heck_Yeah_TVApp.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct Heck_Yeah_TVApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isBootComplete = false
    @State private var startupTask: Task<Void, Never>? = nil
    
    var body: some Scene {
        WindowGroup {
            RootView(isBootComplete: $isBootComplete)
                .ignoresSafeArea(edges: .all)
                .task {
                    startBootstrap()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active {
                        startupTask?.cancel()
                    }
                }
                .modelContainer(DataPersistence.shared.container)
                .modelContext(DataPersistence.shared.viewContext)
        }
    }
    
    private func startBootstrap() {
        // Always ensure guide starts off in the dismissed state when there is a selected channel. Else present the guide.  This prevents a black screen on first startup.
        let appState = SharedAppState.shared
        appState.isGuideVisible = (appState.selectedChannel == nil)
        
        startupTask?.cancel()
        startupTask = Task {
            
            let hdHomeRunController = HDHomeRunDiscoveryController()
            let iptvController: IPTVController = IPTVController()
            let summary = FetchSummary()
            
            let hdHomeRunSummary = await hdHomeRunController.bootStrapTunerChannelDiscovery()
            let iptvSummary = await iptvController.fetchAll()
            summary.mergeSummary(hdHomeRunSummary)
            summary.mergeSummary(iptvSummary)
            
            // TODO: Log summary for collection, analysis and diagnostics.
            if summary.failures.count > 0 {
                logError("ERROR: Failure in bootstrap data fetch: \(summary.failures)")
            }
            
            let container = DataPersistence.shared.container
            Task.detached(priority: .userInitiated) {
                let importer = ChannelImporter(container: container)
                try await importer.importChannels(streams: iptvController.streams, tunerChannels: hdHomeRunController.channels)
                try await importer.buildChannelMap(showFavoritesOnly: SharedAppState.shared.showFavoritesOnly)
                
                await MainActor.run {
                    // Update state variable that fetches are completed, so the boot screen will hide and main app view will load.
                    isBootComplete = true
                }
            }
        }
    }
}
