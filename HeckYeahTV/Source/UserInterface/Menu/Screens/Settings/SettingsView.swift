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
    @State private var channelBundles: [ChannelBundle] = []
    @State private var showingAddBundle = false
    @State private var iptvChannelCount: Int = 0
    @State private var isReloadingIPTV = false
    @State private var discoveredDevices: [HomeRunDevice] = []
    
    private func channelCount(for deviceId: HDHomeRunDeviceId) -> Int {
        let count = (try? swiftDataController.totalChannelCountFor(deviceId: deviceId)) ?? 0
        return count
    }
    
    var body: some View {
        
        List {
            
            // MARK: - Channel Bundles Section
            Section {
                ForEach(channelBundles) { bundle in
                    TVNavigationLink {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bundle.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Text("\(bundle.channels.count) channels")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    } destination: {
                        ChannelBundleDetailView(bundle: bundle)
                    }
                }
                
                Button {
                    showingAddBundle = true
                } label: {
                    Label("Add Channel Bundle", systemImage: "plus.circle.fill")
                }
                .foregroundStyle(.blue)
                
            } header: {
                Text("Channel Bundles")
            } footer: {
                Text("Bundles organize your channels. Tap a bundle to edit its name, filters, and channels.")
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
            
            
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
                    Text("Reloading channels...")
                        .foregroundStyle(.white)
                }
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))

            
            // MARK: - HDHomeRun Devices Section
            Section {
                if discoveredDevices.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No devices discovered")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(discoveredDevices) { device in
                        
                        TVNavigationLink {
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
                        } destination: {
                            DeviceDetailView(device: device)
                        }
                    }
                }
                
                Button {
                    refreshDeviceList()
                } label: {
                    Label("Refresh Devices", systemImage: "arrow.clockwise")
                }
                .foregroundStyle(.blue)
                
            } header: {
                Text("HDHomeRun Devices")
                    .foregroundStyle(.white)
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))

            
        }
        .scrollContentBackground(.hidden)
        
        .sheet(isPresented: $showingAddBundle) {
            AddBundleSheet(onAdd: { name in
                addBundle(name: name)
            })
        }
        .task {
            loadIPTVChannelCount()
            refreshDeviceList()
        }
        
        .onAppear() {
            self.discoveredDevices = (try? swiftDataController.homeRunDevices()) ?? []
            self.channelBundles = (try? swiftDataController.channelBundles()) ?? []
        }
    }
    
    // MARK: - Actions
    
    private func addBundle(name: String) {
        let newBundle = ChannelBundle(id: UUID().uuidString,
                                      name: name,
                                      channels: [])
        swiftDataController.viewContext.insert(newBundle)
        if swiftDataController.viewContext.hasChanges {
            try? swiftDataController.viewContext.save()
        }
    }
    
    private func reloadIPTVChannels() {
        isReloadingIPTV = true
        // TODO: Implement IPTV reload logic
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                isReloadingIPTV = false
                loadIPTVChannelCount()
            }
        }
    }
    
    private func loadIPTVChannelCount() {
        // TODO: Implement actual count from ChannelCatalog
        iptvChannelCount = (try? swiftDataController.totalChannelCount()) ?? 0
    }
    
    private func refreshDeviceList() {
        discoveredDevices = (try? swiftDataController.homeRunDevices()) ?? []
    }
}

// MARK: - Add Bundle Sheet

struct AddBundleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bundleName = ""
    let onAdd: (String) -> Void
    
#if os(tvOS)
    @FocusState private var isNameFieldFocused: Bool
#endif
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bundle Name", text: $bundleName)
#if os(tvOS)
                        .focused($isNameFieldFocused)
#endif
                } header: {
                    Text("New Channel Bundle")
                }
            }
            .navigationTitle("Add Bundle")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(bundleName)
                        dismiss()
                    }
                    .disabled(bundleName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
#if os(tvOS)
            .onAppear {
                isNameFieldFocused = true
            }
#endif
        }
    }
}

// MARK: - Rename Bundle Sheet

struct RenameBundleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var bundle: ChannelBundle
    @State private var newName: String = ""
    
#if os(tvOS)
    @FocusState private var isNameFieldFocused: Bool
#endif
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bundle Name", text: $newName)
#if os(tvOS)
                        .focused($isNameFieldFocused)
#endif
                } header: {
                    Text("Rename Bundle")
                }
            }
            .navigationTitle("Rename")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        bundle.name = newName
                        dismiss()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                newName = bundle.name
#if os(tvOS)
                isNameFieldFocused = true
#endif
            }
        }
    }
}

#Preview("Light Mode") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        HStack(spacing: 0) {
            SettingsView()
                .environment(\.colorScheme, .light)                
        }
    }
}

#Preview("Dark Mode") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        HStack(spacing: 0) {
            SettingsView()
                .environment(\.colorScheme, .dark)
            
        }
    }
}
