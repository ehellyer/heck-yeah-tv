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

/// Creates a function for not (!) for code readability..
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
/// the the task to be cancelled because it was replaced by a similar subsequent
/// programmatically triggered task.
let codeDebounceNS: UInt64 = 10_000_000 //0.01 seconds

/// A value in nanoseconds representing 0.2s or 200ms.
///
/// This is the time to sleep before executing a task, providing a small delay for
/// the the task to be cancelled because it was replaced by a similar subsequent
/// human triggered task. (Such as time between keystrokes when typing, double tapping, etc)
let humanDebounceNS: UInt64 = 200_000_000 //0.2 seconds

/// A TimeInterval of 0.2 seconds
let settleTime: TimeInterval = TimeInterval(0.2)

/// The number of seconds in one hour.
let secondsPerHour: TimeInterval = 3600

@main
struct Heck_Yeah_TVApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isBootComplete = false
    @State private var startupTask: Task<Void, Never>? = nil
    @State private var showTunerPrompt = false
    // Holds the continuation while the tuner-scan alert is displayed.
    // Wrapped in a class so it can be mutated from within the SwiftUI struct.
    @State private var tunerPromptContinuationBox = TunerPromptContinuationBox()
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
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
                await startBootstrap()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    startupTask?.cancel()
                }
            }
            .alert("Scan for HDHomeRun Tuners?", isPresented: $showTunerPrompt) {
                Button("Yes, Scan for Tuners") {
                    tunerPromptContinuationBox.continuation?.resume(returning: true)
                    tunerPromptContinuationBox.continuation = nil
                }
                Button("No Thanks", role: .cancel) {
                    tunerPromptContinuationBox.continuation?.resume(returning: false)
                    tunerPromptContinuationBox.continuation = nil
                }
            } message: {
                Text("Heck Yeah TV can scan your local network for HDHomeRun tuner devices and include their live TV channels in your guide.\n\nIf you don't know what an HDHomeRun is, or you're sure you don't have one, tap No Thanks — you can always enable this later in Settings.")
            }
    }
    
    private func startBootstrap() async {
        if appState.scanForTuners == nil {
            let wantsToScan = await withCheckedContinuation { continuation in
                tunerPromptContinuationBox.continuation = continuation
                showTunerPrompt = true
            }
            appState.scanForTuners = wantsToScan
        }
        
        if appState.scanForTuners == true {
            let lanAuth = LocalNetworkAuthorization()
            let result = await lanAuth.requestAuthorization()
            UserDefaults.lastLANAuthorizationStatus = result
        }
        
        await startBootTasks()
    }
    
    private func startBootTasks() async {
        startupTask?.cancel()
        startupTask = Task.detached(name: "HYTV-background-bootstrap-tasks", priority: .high) {
            let appState: AppStateProvider = InjectedValues[\.sharedAppState]
            let container = await InjectedValues[\.swiftDataController].container
            let chCount = await InjectedValues[\.swiftDataController].totalChannelCount()
            logDebug("Current channel catalog count: \(chCount)")
            
            // Don't fetch unless its been at least six hours from the last fetch. (Or date was nil)
            let date = await appState.dateLastIPTVChannelFetch
            if date.map({ $0 < Date().addingTimeInterval(-secondsPerHour * 6) }) ?? true {
                // Concurrent background thread tasks.
                await withTaskGroup(of: Void.self) { group in
                    let scanForTuners = await appState.scanForTuners ?? false
                    if scanForTuners && UserDefaults.lastLANAuthorizationStatus == .granted {
                        group.addTask {
                            let hdTunerImporter = HomeRunImporter(container: container)
                            let _ = try? await hdTunerImporter.load()
                        }
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
         
            logDebug("Performing final boot tasks")
            let otherBootTasks = SwiftDataBootTasks(container: container)
            try? await otherBootTasks.alignSelectedChannelBundleId()
            try? await otherBootTasks.mapOrphanedBundleEntryWithChannel()
            
            await MainActor.run {
                var appState = appState
                appState.dateLastIPTVChannelFetch = Date()
                
                initializeUIState()

                // Update state variable that boot up processes are completed.
                isBootComplete = true
            }
        }
    }
    
    private func initializeUIState() {

        InjectedValues[\.swiftDataController].invalidateChannelBundleMap()

        let swiftDataController = InjectedValues[\.swiftDataController]
        let hasNoChannels = swiftDataController.channelBundleMap.map.isEmpty
        
        /// Triggers a synchronization event for tuner device(s) channel lineup.
        swiftDataController.invalidateTunerLineUp()
        
        if HeckYeahSchema.versionIdentifier == Schema.Version(0, 0, 0) {
            // DB was deletes as part of a hard reset, so clear out some app state to match.
            appState.selectedChannel = nil
            appState.resetRecentChannelIds()
            appState.isPlayerPaused = false
        }
        
        // Always dismiss channel programs carousel
        appState.showProgramDetailCarousel = nil
        
        // Determine if should show menu.
        appState.showAppMenu = (appState.selectedChannel == nil) || hasNoChannels
        
        // If shown, determine default tab.
        appState.selectedTab = (hasNoChannels) ? .settings : .guide
    }
}

/// Reference-type box for a `CheckedContinuation`, allowing it to be held in a SwiftUI `@State`
/// property and mutated from within an immutable struct. Only ever accessed on the main actor.
@MainActor
final class TunerPromptContinuationBox {
    var continuation: CheckedContinuation<Bool, Never>?
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
        
        let deviceId = IPTVImporter.iptvDeviceId
        let cDescriptor: FetchDescriptor<Channel> = FetchDescriptor<Channel>(
            predicate: #Predicate {
                $0.deviceId == deviceId
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
