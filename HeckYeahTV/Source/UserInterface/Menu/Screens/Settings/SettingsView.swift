//
//  SettingsView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/21/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @Binding var navigationPath: [SettingsDestination]
    @State private var isReloadingIPTV = false
    @State private var isReloadingHomeRun = false
    @State private var iptvChannelCount: Int = 0
    
    @Query(sort: \ChannelBundle.name)
    private var channelBundles: [ChannelBundle]
    
    @Query(sort: \HomeRunDevice.friendlyName)
    private var homeRunDevices: [HomeRunDevice]
    
    private func channelCount(for deviceId: HDHomeRunDeviceId) -> Int {
        let count = swiftDataController.channelCountFor(deviceId: deviceId)
        return count
    }
    
    var body: some View {
        
        List {
            
            // MARK: - Active Bundle
            if channelBundles.count > 1 {
                Section {
                    let selectedName = channelBundles.first(where: { $0.id == appState.selectedChannelBundleId })?.name ?? ""
                    Menu {
                        ForEach(channelBundles) { bundle in
                            Button {
                                appState.selectedChannelBundleId = bundle.id
                            } label: {
                                HStack {
                                    Text(bundle.name)
                                    if bundle.id == appState.selectedChannelBundleId {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedName)
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.white)
                        }
                    }
                } header: {
                    Text("Active Bundle")
                } footer: {
                    Text("The active bundle determines which channels appear in the guide.")
                }
                .foregroundStyle(.white)
                .listRowBackground(Color(white: 0.1).opacity(0.8))
#if !os(tvOS)
                .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
#endif
            }
            
            
            // MARK: - Manage Bundles
            Section {
                ForEach(channelBundles) { bundle in
                    
                    NavigationLink(value: SettingsDestination.bundleDetail(bundleId: bundle.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bundle.name)
                                .font(.body)
                            Text(subtext(for: bundle))
                                .font(.caption)
                        }
                    }
                }
                
                Button {
                    navigationPath.append(.addBundle)
                } label: {
                    Label("Add Channel Bundle", systemImage: "plus.circle.fill")
                }
                .foregroundStyle(.blue)
                
            } header: {
                Text("Manage Bundles")
            } footer: {
                Text("Tap a bundle to edit its name, filters, and channels.")
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
#if !os(tvOS)
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
#endif
            
            
            // MARK: - IPTV Section
            Section {
                HStack {
                    Text("Available Channels")
                    Spacer()
                    Text("\(iptvChannelCount)")
                }
                
                Button {
                    reloadIPTVChannels()
                } label: {
                    Label("Reload IPTV Channels", systemImage: "arrow.clockwise")
                }
                .foregroundStyle(.blue)
                .disabled(isReloadingIPTV)
            } header: {
                Text("IPTV")
                    .foregroundStyle(.white)
            } footer: {
                if isReloadingIPTV {
                    Text("Reloading channels, this may take up to a minute...")
                        .foregroundStyle(.white)
                }
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
#if !os(tvOS)
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
#endif
            
            
            // MARK: - HDHomeRun Devices Section
            Section {
                if homeRunDevices.isEmpty {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .foregroundStyle(.secondary)
                        Text("No devices discovered")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    ForEach(homeRunDevices) { device in
                        NavigationLink {
                            DeviceDetailView(device: device)
                        } label: {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.friendlyName)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Text("\(channelCount(for: device.deviceId)) channels")
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                }
                
                Button {
                    reloadTunerDevices()
                } label: {
                    Label("Refresh Devices", systemImage: "arrow.clockwise")
                }
                .foregroundStyle(.blue)
                .disabled(isReloadingHomeRun)
            } header: {
                Text("HDHomeRun Devices")
                    .foregroundStyle(.white)
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
#if !os(tvOS)
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
#endif
        }
#if !os(tvOS)
        .scrollContentBackground(.hidden)
#endif
        .navigationDestination(for: SettingsDestination.self) { destination in
            switch destination {
                case .addBundle:
                    AddBundleView(navigationPath: $navigationPath, onAdd: { bundle in
                        navigationPath.append(.bundleDetail(bundleId: bundle.id))
                    })
                case .bundleDetail(let bundleId):
                    if let bundle = channelBundles.first(where: { $0.id == bundleId }) {
                        ChannelBundleDetailView(navigationPath: $navigationPath,
                                                bundle: bundle)
                    }
            }
        }
        .onAppear() {
            reloadIPTVChannelCount()
        }
    }
    
    private func reloadIPTVChannelCount() {
        iptvChannelCount = swiftDataController.totalIPChannelCatalogCount()
    }
    
    private func subtext(for bundle: ChannelBundle) -> String {
        let hasTunerEnabled = homeRunDevices.first(where: { $0.includeChannelLineUp }) != nil
        var subtext = "\(bundle.channels.count) channels in bundle"
        subtext = subtext + ((hasTunerEnabled) ? ", (inc. Tuner Channels)." : ".")
        return subtext
    }
    
    // MARK: - Actions
    
    private func reloadIPTVChannels() {
        isReloadingIPTV = true
        Task.detached(name: "HeckYeahTV.IPTVImporter") {
            let container = await swiftDataController.container
            let importer = IPTVImporter(modelContainer: container)
            do {
                _ = try await importer.load()
                
            } catch {
                logError("Reload tuner devices failed.  Error: \(error)")
            }
            await MainActor.run {
                reloadIPTVChannelCount()
                isReloadingIPTV = false
            }
        }
    }
    
    private func reloadTunerDevices() {
        isReloadingHomeRun = true
        Task.detached(name: "HeckYeahTV.HomeRunImporter") {
            let container = await swiftDataController.container
            let importer = HomeRunImporter(modelContainer: container)
            do {
                _ = try await importer.load(shouldFetchGuideData: true)
            } catch {
                logError("Reload tuner devices failed.  Error: \(error)")
            }
            await MainActor.run {
                isReloadingHomeRun = false
            }
        }
    }
}




#Preview("Light Mode") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    @Previewable @State var navigationPath: [SettingsDestination] = []
    
    // Override the injected AppStateProvider
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        NavigationStack(path: $navigationPath) {
            SettingsView(navigationPath: $navigationPath)
                .environment(\.colorScheme, .light)
                .modelContext(swiftDataController.viewContext)
        }
    }
}

#Preview("Dark Mode") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    @Previewable @State var navigationPath: [SettingsDestination] = []
    
    // Override the injected AppStateProvider
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        NavigationStack(path: $navigationPath) {
            SettingsView(navigationPath: $navigationPath)
                .environment(\.colorScheme, .dark)
                .modelContext(swiftDataController.viewContext)
        }
    }
}
