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
    @State private var dataPersistence: SwiftDataStack = SwiftDataStack.shared
    
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
            
            let container = dataPersistence.container
            
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
//                writeMockFiles()
                
                // Update state variable that boot up processes are completed.
                isBootComplete = true
            }
        }
    }
}

extension Heck_Yeah_TVApp {
    
#if DEBUG
    //TODO: EJH - Comment out for release.
    //Rough code for developer only - Not production code.
    func writeMockFiles() {
        let cpDescriptor: FetchDescriptor<ChannelProgram> = FetchDescriptor<ChannelProgram>(
            sortBy: [
                SortDescriptor(\ChannelProgram.channelId),
                SortDescriptor(\ChannelProgram.startTime)
            ]
        )
        
        let cDescriptor: FetchDescriptor<Channel> = FetchDescriptor<Channel>(
            predicate: #Predicate {
                $0.country == "ANY" && $0.source == "homeRunTuner"
            },
            sortBy: [
                SortDescriptor(\Channel.sortHint)
            ]
        )
        
        let viewContext = dataPersistence.viewContext
        
        let fetchedChannels: [Channel]? = try? viewContext.fetch(cDescriptor)
        let fetchedPrograms: [ChannelProgram]? = try? viewContext.fetch(cpDescriptor)
        
        let jsonChanelsString = try? fetchedChannels?.toJSONString()
        let jsonChanelProgramsString = try? fetchedPrograms?.toJSONString()
        
        let rootURL = SwiftDataStack.shared.appFileStoreRootURL
        
        let channelsURL = rootURL.appendingPathComponent("MockChannels", isDirectory: false).appendingPathExtension("json")
        let channelProgramsURL = rootURL.appendingPathComponent("MockChannelPrograms", isDirectory: false).appendingPathExtension("json")
        
        try? jsonChanelsString?.write(to: channelsURL, atomically: true, encoding: .utf8)
        try? jsonChanelProgramsString?.write(to: channelProgramsURL, atomically: true, encoding: .utf8)
    }
#endif
}
