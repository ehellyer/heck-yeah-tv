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
    
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @Binding var navigationPath: [SettingsDestination]
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
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Active Bundle")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } footer: {
                    Text("The active bundle determines which channels appear in the guide.")
                        .foregroundStyle(.white)
                }
            }
            
            
            // MARK: - Manage Bundles
            Section {
                ForEach(channelBundles) { bundle in
                    NavigationLink(value: SettingsDestination.bundleDetail(bundleId: bundle.id)) {
                        
                        HStack(spacing: 20) {
                            Image(systemName: "pencil")
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bundle.name)
                                    .font(.body)
                                
                                Text(subtext(for: bundle))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Button {
                    navigationPath.append(.addBundle)
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Add Channel Bundle")
                            .font(.body)
                    }
                }
                .buttonStyle(.glass)
                .foregroundStyle(.primary)
                
            } header: {
                Text("Manage Bundles")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } footer: {
                Text("Tap a bundle to edit its name, filters, and channels.")
                    .foregroundStyle(.white)
            }
            
            
            // MARK: - IPTV Section
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Channels")
                    Text("\(iptvChannelCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                
                Button {
                    reloadIPTVChannels()
                } label: {
                    HStack(spacing: 20) {
                        if appState.isReloadingIPTV {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.blue)
                        }
                        Text("Reload IPTV Channels")
                            .font(.body)
                    }
                }
                .buttonStyle(.glass)
                .foregroundStyle(.primary)
                .disabled(appState.isReloadingIPTV)
            } header: {
                Text("IPTV")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } footer: {
                if appState.isReloadingIPTV {
                    Text("Reloading channels, this may take up to a minute...")
                        .foregroundStyle(.white)
                }
            }
           
            
            
            // MARK: - HDHomeRun Devices Section
            Section {
                if homeRunDevices.isEmpty {
                    HStack(spacing: 20) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .foregroundStyle(.blue)
                        Text("No devices discovered")
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                } else {
                    ForEach(homeRunDevices) { device in
                        NavigationLink {
                            DeviceDetailView(device: device)
                        } label: {
                            HStack(spacing: 20) {
                                if device.isEnabled {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundStyle(.blue)
                                } else {
                                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                        .foregroundStyle(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.friendlyName)
                                        .font(.body)
                                    
                                    HStack {
                                        Text("\(channelCount(for: device.deviceId)) channels")
                                        
                                        if device.isEnabled {
                                            Text("(Available for including in channel bundle)")
                                        } else {
                                            Text("(Disabled for channel bundles)")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                
                
                Button {
                    reloadTunerDevices()
                } label: {
                    HStack(spacing: 20) {
                        if appState.isReloadingHomeRun {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.blue)
                        }
                        Text("Refresh Devices")
                            .font(.body)
                    }
                }
                .buttonStyle(.glass)
                .foregroundStyle(.primary)
                .disabled(appState.isReloadingHomeRun)
            } header: {
                Text("HDHomeRun Devices")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } footer: {
                if appState.isReloadingHomeRun {
                    Text("Probing network for tuner devices...")
                        .foregroundStyle(.white)
                }
            }
        }

#if !os(tvOS)
        .scrollContentBackground(.hidden)
#endif
#if os(macOS)
        .listRowSeparator(.hidden)
        .listSectionSeparator(.hidden)
#endif
        .navigationDestination(for: SettingsDestination.self) { destination in
            switch destination {
                case .addBundle:
                    AddBundleView(navigationPath: $navigationPath, onAdd: { bundle in
                        // Copy path, edit copy to prevent redraws and strange animations, then set back.
                        var navPath = navigationPath
                        navPath.removeAll(where: { $0 == .addBundle })
                        navPath.append(.bundleDetail(bundleId: bundle.id))
                        navigationPath = navPath
                    })
                case .bundleDetail(let bundleId):
                    if let bundle = channelBundles.first(where: { $0.id == bundleId }) {
                        ChannelBundleFilterView(navigationPath: $navigationPath,
                                                bundle: bundle)
                    }
            }
        }
        .onAppear() {
            reloadIPTVChannelCount()
        }
    }
    
    // MARK: - Private View API

    private func subtext(for bundle: ChannelBundle) -> String {
        let hasTunerEnabled = bundle.deviceAssociations.count > 0
        var subtext = "\(bundle.bundleChannelCount) channels in bundle"
        subtext = subtext + ((hasTunerEnabled) ? ", (inc. Tuner Channels)." : ".")
        return subtext
    }

    private func reloadIPTVChannelCount() {
        iptvChannelCount = swiftDataController.totalIPChannelCatalogCount()
    }
    
    private func reloadIPTVChannels() {
        Task.detached(name: "HeckYeahTV.IPTVImporter") {
            let container = await swiftDataController.container
            let importer = IPTVImporter(modelContainer: container)
            do {
                _ = try await importer.load()
                
            } catch {
                logError("Reload IPTV channels failed.  Error: \(error)")
            }
            await MainActor.run {
                reloadIPTVChannelCount()
            }
        }
    }
    
    private func reloadTunerDevices() {
        Task.detached(name: "HeckYeahTV.HomeRunImporter") {
            let container = await swiftDataController.container
            let importer = HomeRunImporter(modelContainer: container)
            do {
                _ = try await importer.load(shouldFetchGuideData: true)
            } catch {
                logError("Reload tuner devices failed.  Error: \(error)")
            }
        }
    }
}



//MARK: - Previews

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
                .modelContext(swiftDataController.viewContext)
        }
    }
    .environment(\.colorScheme, .light)
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
                .modelContext(swiftDataController.viewContext)
        }
    }
    .environment(\.colorScheme, .dark)
}
