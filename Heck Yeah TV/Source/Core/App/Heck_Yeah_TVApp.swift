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
    
    @State private var guideStore = GuideStore()
    @State private var isReady = false
    @State private var hdHomeRunController = HDHomeRunDiscoveryController()
    @State private var iptvController: IPTVController = IPTVController()
    @State private var startupTask: Task<Void, Never>? = nil
    
    var body: some Scene {
        WindowGroup {
            RootView(isReady: $isReady)
                .ignoresSafeArea(edges: .all)
                .task {
                    startBootstrap()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active {
                        startupTask?.cancel()
                    }
                }
                .environment(guideStore)
                .modelContainer(Persistence.shared.container)
        }
       
    }
    
    private func startBootstrap() {
        startupTask?.cancel()
        startupTask = Task {
            let summary = FetchSummary()
            let hdHomeRunSummary = await hdHomeRunController.bootStrapTunerChannelDiscovery()
            let iptvSummary = await iptvController.fetchAll()
            summary.mergeSummary(hdHomeRunSummary)
            summary.mergeSummary(iptvSummary)
            
            // TODO: Log summary for collection, analysis and diagnostics.
            if summary.failures.count > 0 {
                print("ERROR: Failure in bootstrap data fetch: \(summary.failures)")
            }
            
            let importer = ChannelImporter(container: Persistence.shared.container)
            Task.detached(priority: .userInitiated) {
                try await importer.importChannels(streams: iptvController.streams, tunerChannels: hdHomeRunController.channels)
                
                // No UI touching here. UI will re-fetch/react on main.
                await MainActor.run {
                    // Update state variable that fetches are completed, so the boot screen will hide and main app view will load.
                    isReady = true
                }
            }
        }
    }
}
