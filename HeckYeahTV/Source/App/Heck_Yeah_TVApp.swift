//
//  Heck_Yeah_TVApp.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData
import FirebaseCore

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
    
    // Register the legacy app delegate for Firebase initialization.
#if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
#elseif canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
#endif
    
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isBootComplete = false
    @State private var startupTask: Task<Void, Never>? = nil
    @State private var showTunerPrompt = false
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    
    // Holds the continuation while the tuner-scan alert is displayed.
    // Wrapped in a class so it can be mutated from within the SwiftUI struct.
    @State private var tunerPromptContinuationBox = TunerPromptContinuationBox()
    
    @State private var needsDefaultChannels: Bool = false
    
    var body: some Scene {
#if os(macOS)
        Window("Heck Yeah TV", id: "main") {
            content()
        }
//        #if DEBUG
//        Window("HDHomeRun Probe Test", id: "probe-test") {
//            HDHomeRunProbeTestView()
//        }
//        .keyboardShortcut("t", modifiers: [.command, .shift])
//        #endif
#else
        WindowGroup {
            content()
        }
#endif
    }
    
    private func content() -> some View {
        RootView(isBootComplete: $isBootComplete)
            .preferredColorScheme(.dark) // Using transparency with transparent black requires us to lock into dark theme else text will not be contrasted enough to read.
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
                    resumeTunerPromptContinuation(returning: true)
                }
                Button("No Thanks", role: .cancel) {
                    resumeTunerPromptContinuation(returning: false)
                }
            } message: {
                Text("Heck Yeah TV can scan your local network for HDHomeRun tuner devices and include their live TV channels in your guide.\n\nIf you don't know what an HDHomeRun is, or you're sure you don't have one, tap No Thanks - you can always enable this later in Settings.")
            }
    }
    
    private func startBootstrap() async {
        logDebug("Ask to scan for tuners, which may prompt for network access.")
        await askToRequestNetworkProbePermission()
        
        if appState.scanForTuners == true {
            logDebug("User has chosen to scan for tuners. Requesting local network access.")
            let lanAuth = LocalNetworkAuthorization()
            let result = await lanAuth.requestAuthorization()
            UserDefaults.lastLANAuthorizationStatus = result
        } else {
            logDebug("User has chosen not to scan for tuners.")
        }
        
        await startBootTasks()
    }
    
    private func askToRequestNetworkProbePermission() async {
#if !os(tvOS)
        if appState.scanForTuners == nil {
            let wantsToScan = await withCheckedContinuation { continuation in
                tunerPromptContinuationBox.continuation = continuation
                showTunerPrompt = true
            }
            appState.scanForTuners = wantsToScan
        }
#else
        // tvOS does not support local network privacy.
        appState.scanForTuners = true
#endif
    }
    
    private func resumeTunerPromptContinuation(returning: Bool) {
        tunerPromptContinuationBox.continuation?.resume(returning: returning)
        tunerPromptContinuationBox.continuation = nil
    }
    
    private func startBootTasks() async {
        logDebug("Starting boot tasks on detached thread...")
        startupTask?.cancel()
        startupTask = Task.detached(name: "HYTV-background-bootstrap-tasks", priority: .high) {
            await preImportBootTasks()
            
            await withTaskGroup(of: Void.self) { group in
                
                // Determine if we need to block on IPTV fetch
                // If we have no channels at all, we MUST wait for IPTV import to complete
                // Otherwise, we can proceed immediately and refresh in the background
                let hasExistingIPTVChannels = await swiftDataController.hasIPTVChannelsInStore
                if not(hasExistingIPTVChannels) {
                    logDebug("No existing IPTV channels - blocking boot to fetch initial catalog")
                    group.addTask {
                        await importIPTV()
                    }
                } else {
                    logDebug("Loading IPTV channels in the background, without blocking the boot sequence.")
                    Task {
                        await importIPTV()
                    }
                }
                
                group.addTask {
                    await importHDHomeRun()
                }
                
                // Wait for all background tasks to complete
                await group.waitForAll()
            }

            // Run essential boot tasks that must complete before showing UI
            await postImportBootTasks()

            await MainActor.run {
                // Complete boot - UI can now be shown
                initializeUIState()
                
                // Update state variable that boot up processes are completed.
                isBootComplete = true
            }
        }
    }
    
    private func importIPTV() async {
        logDebug("Import IPTV: Starting IPTV catalog refresh.")
        let container = InjectedValues[\.swiftDataController].container
        let iptvImporter = IPTVImporter(modelContainer: container)
        let _ = try? await iptvImporter.load()
        logDebug("🏁 Import IPTV: Completed IPTV catalog refresh.")
    }
    
    private func importHDHomeRun() async {
        let appState: AppStateProvider = InjectedValues[\.sharedAppState]
        let scanForTuners = appState.scanForTuners ?? false
        
        if scanForTuners && UserDefaults.lastLANAuthorizationStatus == .granted {
            logDebug("Import HDHomeRun: Starting HDHomeRun tuner scan and import.")
            
            let lastGuideFetchDate: Date? = appState.dateLastHomeRunChannelProgramFetch
            
            let shouldFetchGuideData: Bool = {
                guard let lastFetchDate = lastGuideFetchDate else {
                    // Never fetched before, should fetch now
                    return true
                }
                
                // Random interval between 3 and 6 hours
                let randomHours = Double.random(in: 3...6)
                let intervalSinceLastFetch = Date().timeIntervalSince(lastFetchDate)
                let hoursElapsed = intervalSinceLastFetch / 3600 // Convert seconds to hours
                
                return hoursElapsed >= randomHours
            }()
            
            let container = InjectedValues[\.swiftDataController].container
            let hdTunerImporter = HomeRunImporter(modelContainer: container)
            let _ = try? await hdTunerImporter.load(targetDevice: nil, shouldFetchGuideData: shouldFetchGuideData)
            
            // After tuner imports or removals, run the channel cleanup.
            await hdTunerImporter.deleteOrphanedTunerChannels()
            
            logDebug("🏁 Import HDHomeRun: Completed HDHomeRun tuner scan and import.")
        }
    }

    private func preImportBootTasks() async {
        logDebug("Pre Import Task: Starting pre import boot tasks")
        let container = InjectedValues[\.swiftDataController].container
        let bootTasks = SwiftDataBootTasks(container: container)
        self.needsDefaultChannels = (try? await bootTasks.checkDefaultChannelBundle()) ?? false
    }
    
    private func postImportBootTasks() async {
        logDebug("Post Import Task: Starting post import boot tasks")
        let container = InjectedValues[\.swiftDataController].container
        let otherBootTasks = SwiftDataBootTasks(container: container)
        try? await otherBootTasks.alignSelectedChannelBundleId()
        try? await otherBootTasks.mapOrphanedBundleEntryWithChannel()
        if self.needsDefaultChannels {
            try? await otherBootTasks.addDefaultChanels()
        }
        logDebug("🏁 Post Import Task: Completed post import boot tasks")
    }
    
    private func initializeUIState() {
        let swiftDataController = InjectedValues[\.swiftDataController]
        swiftDataController.invalidateTunerLineUp()
        swiftDataController.rebuildChannelBundleMapImmediately()
        
        let hasNoChannels = swiftDataController.channelBundleMap.channelIds.isEmpty
        
        if HeckYeahSchema.versionIdentifier == Schema.Version(0, 0, 0) {
            // DB was deleted as part of a hard reset, so clear out some app state to match.
            swiftDataController.selectedChannel = nil
            appState.isPlayerPaused = false
            swiftDataController.cleanupOldRecentlyViewedChannels(maxCount: 0)
        }
        
        // Always dismiss channel programs carousel
        appState.showProgramDetailCarousel = nil
        
        // Determine if should show menu.
        appState.showAppMenu = hasNoChannels
        
        // If shown, determine default tab.
        appState.selectedTab = (hasNoChannels) ? .settings : .guide
        
        // If there is no current channel selected (as would be for first launch), select the first available channel.
        if swiftDataController.selectedChannel == nil, let channelId = swiftDataController.channelBundleMap.channelIds.first, let channel = swiftDataController.channel(for: channelId) {
            swiftDataController.selectedChannel = channel
        }
        
        logDebug("All bootstrap tasks completed, starting up main UI... ✅")
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
    //EJH - Do not include in release compilation.
    //EJH - Rough code for developer only - Not production code.
    func writeMockFiles() {
        let cpDescriptor: FetchDescriptor<ChannelProgram> = ChannelProgramPredicate().fetchDescriptor(sortBy: [SortDescriptor(\.channelId),
                                                                                                               SortDescriptor(\.startTime)])
        
        let deviceId = IPTVImporter.iptvDeviceId
        let cDescriptor = ChannelPredicate(deviceIds: [deviceId]).fetchDescriptorDefaultSort()
        
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
    
    func generateDefaultIPTVData() {
        let viewContext = InjectedValues[\.swiftDataController].viewContext
        //Note to future Ed: Assumes only one ChannelBundle of BundleEntries.
        let fetchDescriptor: FetchDescriptor<BundleEntry> = BundleEntryPredicate(hasChannel: true).fetchDescriptorDefaultSort()
        let bundleEntries: [BundleEntry] = try! viewContext.fetch(fetchDescriptor)
        let channels = bundleEntries.filter({ $0.channel?.deviceId == IPTVImporter.iptvDeviceId }).map { $0.channel!.id }
        let jsonData = try! JSONEncoder().encode(channels)
        
        let rootURL = AppKeys.Application.appFileStoreRootURL
        let channelsURL = rootURL.appendingPathComponent("DefaultChannels", isDirectory: false).appendingPathExtension("json")
        logDebug(channelsURL.path(percentEncoded: false))
        
        try? jsonData.write(to: channelsURL)
    }
#endif
}
