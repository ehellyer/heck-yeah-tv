//
//  Heck_Yeah_TVApp.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//

import SwiftUI

@main
struct Heck_Yeah_TVApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isReady = false
    @State private var hdHomeRunController = HDHomeRunTunerDiscoveryController()
    @State private var iptvController: IPTVController = IPTVController()
    @State private var startupTask: Task<Void, Never>? = nil
    
    
    
    var body: some Scene {
        WindowGroup {
            ZStack() {
                BackgroundView()
                PlatformRootView(isReady: $isReady)
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
    }
    
    private func startBootstrap() {
        startupTask?.cancel()
        startupTask = Task {
            do {
                let _ = try await hdHomeRunController.bootStrapTunerChannelDiscovery()
                let _ = await iptvController.fetchAll()
            } catch {
                print(error)
            }
            
            await MainActor.run {
                isReady = true
            }
        }
    }
}

//#Preview() {
//    
//        
//}
