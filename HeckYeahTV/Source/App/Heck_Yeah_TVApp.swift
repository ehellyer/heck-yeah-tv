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

/// A TimeInterval of 0.2 seconds
let settleTime: TimeInterval = TimeInterval(0.2)

@main
struct Heck_Yeah_TVApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isBootComplete = false
    @State private var startupTask: Task<Void, Never>? = nil
    
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
            .preferredColorScheme(.dark)
            .task {
                startBootstrap()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    startupTask?.cancel()
                }
            }
    }
    
    private func startBootstrap() {
        
        startupTask?.cancel()
        startupTask = Task.detached(name: "Bootstrap tasks", priority: .userInitiated) {
            let appState: AppStateProvider = InjectedValues[\.sharedAppState]
            
            let chCount = await (try? InjectedValues[\.swiftDataController].totalChannelCount()) ?? 0
            logDebug("Current channel catalog count: \(chCount)")
            
            // Don't fetch unless its been at least six hours from the last fetch.
            let date = await appState.dateLastIPTVChannelFetch
            if chCount == 0 || date == nil || date! < Date().addingTimeInterval(-60 * 60 * 6) {
                let container = await InjectedValues[\.swiftDataController].container
                
                await withTaskGroup(of: Void.self) { group in
                    
                    group.addTask {
                        let scanForTuners = await appState.scanForTuners
                        let hdTunerImporter = HomeRunImporter(container: container, scanForTuners: scanForTuners)
                        let _ = try? await hdTunerImporter.load()
                    }
                    
                    group.addTask {
                        let iptvImporter = IPTVImporter(container: container)
                        let _ = try? await iptvImporter.load()
                    }
                }
                
                await MainActor.run {
                    var appState = appState
                    appState.dateLastIPTVChannelFetch = Date()
                }
            }
            
            await MainActor.run {
                //DEV TIME THING
#if DEBUG
                // Writes files based on data in SwiftData, to be used in MockData for previews.
//                writeMockFiles()
#endif
                
                setInitialUI()
                
                // Update state variable that boot up processes are completed.
                isBootComplete = true
            }
        }
    }
    
    // Always ensure app navigation starts off in the dismissed state when there is a selected channel. Else present the default tab in app navigation.  This prevents a black screen on first startup.
    private func setInitialUI() {
        var appState: AppStateProvider = InjectedValues[\.sharedAppState]
        
        let swiftDataController = InjectedValues[\.swiftDataController]
        let hasNoChannels = swiftDataController.channelBundleMap.map.isEmpty
        
        // Always dismiss channel programs carousel
        appState.showProgramDetailCarousel = nil
        
        // Determine if should show menu.
        appState.showAppMenu = (appState.selectedChannel == nil) || hasNoChannels
        
        // If shown, determine default tab.
        appState.selectedTab = (hasNoChannels) ? .settings : .guide
    }
}

extension Heck_Yeah_TVApp {
    
#if DEBUG
    //TODO: EJH - Comment out for release.
    //Rough code for developer only - Not production code.
    func writeMockFiles() {
        let cpDescriptor: FetchDescriptor<ChannelProgram> = FetchDescriptor<ChannelProgram>(
            sortBy: [
                SortDescriptor(\.channelId),
                SortDescriptor(\.startTime)
            ]
        )
        
        let cDescriptor: FetchDescriptor<Channel> = FetchDescriptor<Channel>(
            predicate: #Predicate {
                $0.country == "ANY" && $0.source == "homeRunTuner"
            },
            sortBy: [
                SortDescriptor(\.sortHint)
            ]
        )
        
        let viewContext = InjectedValues[\.swiftDataController].viewContext
        
        let fetchedChannels: [Channel]? = try? viewContext.fetch(cDescriptor)
        let fetchedPrograms: [ChannelProgram]? = try? viewContext.fetch(cpDescriptor)
        
        let jsonChanelsString = try? fetchedChannels?.toJSONString()
        let jsonChanelProgramsString = try? fetchedPrograms?.toJSONString()
        
        let rootURL = AppKeys.Application.appFileStoreRootURL
        let channelsURL = rootURL.appendingPathComponent("MockChannels", isDirectory: false).appendingPathExtension("json")
        let channelProgramsURL = rootURL.appendingPathComponent("MockChannelPrograms", isDirectory: false).appendingPathExtension("json")
        
        try? jsonChanelsString?.write(to: channelsURL, atomically: true, encoding: .utf8)
        try? jsonChanelProgramsString?.write(to: channelProgramsURL, atomically: true, encoding: .utf8)
    }
#endif
}
