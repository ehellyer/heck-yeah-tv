//
//  Heck_Yeah_TVApp.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

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
            ZStack() {
                RootView(isReady: $isReady)
                    .environment(guideStore)
            }
            .task {
                startBootstrap()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    startupTask?.cancel()
                }
            }
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
                print("Failed to bootstrap: \(summary.failures)")
            }
            
            await self.guideStore.load(streams: iptvController.streams, tunerChannels: hdHomeRunController.channels)
            await MainActor.run {
                // Signal channel fetch is completed, so the boot screen will hide and main app view will load.
                isReady = true
            }
        }
    }
}
