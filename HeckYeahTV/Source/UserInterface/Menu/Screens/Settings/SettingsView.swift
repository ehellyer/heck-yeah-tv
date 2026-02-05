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
    @State private var bundleToDelete: ChannelBundle?
    @State private var showingDeleteConfirmation = false
    @State private var editingBundle: ChannelBundle?
    @State private var iptvChannelCount: Int = 0
    @State private var isReloadingIPTV = false
    @State private var discoveredDevices: [HomeRunDevice] = []
    
    private func channelCount(for deviceId: HDHomeRunDeviceId) -> Int {
        let count = (try? swiftDataController.totalChannelCountFor(deviceId: deviceId)) ?? 0
        return count
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Channel Bundles Section
                Section {
                    ForEach(channelBundles) { bundle in
                        NavigationLink {
                            EditBundleChannelsView(bundle: bundle)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bundle.name)
                                        .font(.body)
                                    Text("\(bundle.channels.count) channels")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
#if !os(tvOS)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                bundleToDelete = bundle
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(channelBundles.count <= 1)
                            
                            Button {
                                editingBundle = bundle
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
#endif
                    }
                    
                    Button {
                        showingAddBundle = true
                    } label: {
                        Label("Add Channel Bundle", systemImage: "plus.circle.fill")
                    }
                    .foregroundStyle(.blue)
                    
                } header: {
                    Text("Channel Bundles")
                }
                
                // MARK: - IPTV Section
                Section {
                    HStack {
                        Text("Available Channels")
                        Spacer()
                        Text("\(iptvChannelCount)")
                            .foregroundStyle(.secondary)
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
                } footer: {
                    if isReloadingIPTV {
                        Text("Reloading channels...")
                            .foregroundStyle(.secondary)
                    }
                }
                
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
                            NavigationLink {
                                DeviceDetailView(device: device)
                            } label: {
                                HStack {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundStyle(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(device.friendlyName)
                                            .font(.body)
                                        
                                        Text("\(channelCount(for: device.deviceId)) channels")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
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
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddBundle) {
                AddBundleSheet(onAdd: { name in
                    addBundle(name: name)
                })
            }
            .sheet(item: $editingBundle) { bundle in
                RenameBundleSheet(bundle: bundle)
            }
            .alert("Delete Channel Bundle", isPresented: $showingDeleteConfirmation, presenting: bundleToDelete) { bundle in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteBundle(bundle)
                }
            } message: { bundle in
                Text("Are you sure you want to delete '\(bundle.name)'? This action cannot be undone.")
            }
            .task {
                loadIPTVChannelCount()
                refreshDeviceList()
            }
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
    
    private func deleteBundle(_ bundle: ChannelBundle) {
        guard channelBundles.count > 1 else { return }
        swiftDataController.viewContext.delete(bundle)
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
