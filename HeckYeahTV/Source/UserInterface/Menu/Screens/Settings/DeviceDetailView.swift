//
//  DeviceDetailView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/20/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

fileprivate let leadingPadding: CGFloat = 8

struct DeviceDetailView: View {
    
    let device: HomeRunDevice
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]

    var body: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 8) {
                
                // MARK: - Settings Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        if device.isOffline {
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                    Text("Delete HomeRun Device")
                                }
                                .foregroundStyle(.primary)
                            }
                            .buttonStyle(.glass)
                        }
                        
                        Button(action: {
                            device.isEnabled.toggle()
                        }) {
                            
                            if device.isEnabled {
                                HStack(spacing: 10) {
                                    Image(systemName: "power")
                                        .foregroundStyle(.blue)
                                    Text("Disable")
                                }
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "power")
                                        .foregroundStyle(.gray)
                                    Text("Enable")
                                }
                            }
                            
                        }
                        .buttonStyle(.glass)
                    }
                    .foregroundStyle(.primary)

                } header: {
                    SectionHeader("Settings")
                } footer: {
                    Text("Enabled device channels are available to include in any channel bundle.  Edit channel bundle to include/exclude this tuners channels.")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
#if os(tvOS)
                .padding(.leading, leadingPadding)
#endif
                
                // MARK: - Device Info Section
                FocusableSection {
                    SectionHeader("Device Information")
                } content: {
                    DetailRow(label: "Name", value: device.friendlyName)
                    DetailRow(label: "Model", value: device.modelNumber)
                    DetailRow(label: "Device ID", value: device.deviceId)
                    VStack(alignment: .leading, spacing: 20) {
                        StatusRow(label: "Status", isOffline: device.isOffline)
                        
                    }
                }
                
                // MARK: - Firmware Section
                FocusableSection {
                    SectionHeader("Firmware")
                } content: {
                    DetailRow(label: "Firmware Name", value: device.firmwareName)
                    DetailRow(label: "Version", value: device.firmwareVersion)
                }
                
                // MARK: - Network Section
                FocusableSection {
                    SectionHeader("Network")
                } content: {
                    DetailRow(label: "Base URL", value: device.baseURL.absoluteString)
                }
                
                // MARK: - Tuners Section
                FocusableSection {
                    SectionHeader("Tuners")
                } content: {
                    DetailRow(label: "Tuner Count", value: "\(device.tunerCount)")
                    let channelCount = swiftDataController.channelCountFor(deviceId: device.deviceId)
                    DetailRow(label: "Channel Count", value: "\(channelCount)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .contentMargins(10, for: .scrollContent)
#if os(tvOS)
        .clipped()
        .focusSection()
#endif
        .navigationTitle("Tuner Details")
#if !os(tvOS)
        .scrollContentBackground(.hidden)
#endif

#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .background(.clear)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: refreshDevice) {
                    if appState.isReloadingHomeRun {
                        ProgressView()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.gray)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.glass)
                .disabled(appState.isReloadingHomeRun)
            }
        }
        .onChange(of: device.isEnabled) {
            swiftDataController.invalidateTunerLineUp()
        }
        .confirmationDialog(
            "Delete '\(device.friendlyName)'?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Device", role: .destructive) {
                deleteHomeRunDevice()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All channels from this device will be removed from your channel bundles.  You will lose any favorited channels.")
        }
    }

    
    // MARK: - Actions
    
    private func refreshDevice() {
        guard not(appState.isReloadingHomeRun) else { return }
        
        Task {
            let container = swiftDataController.container
            let importer = HomeRunImporter(modelContainer: container)
            guard let target = device.homeRunDiscovery else { return }
            let _ = try? await importer.load(targetDevice: target, shouldFetchGuideData: true)
        }
    }
    
    private func deleteHomeRunDevice() {
        swiftDataController.viewContext.delete(device)
        dismiss()
    }
}

// MARK: - Section Header Component

fileprivate struct SectionHeader: View {
    let title: String

    static let topPadding: CGFloat = 30
    
    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.top, SectionHeader.topPadding)
    }
}

// MARK: - Detail Row Component

fileprivate struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Status Row Component

fileprivate struct StatusRow: View {
    let label: String
    let isOffline: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Image(systemName: isOffline ? "antenna.radiowaves.left.and.right.slash" : "antenna.radiowaves.left.and.right")
                    .foregroundStyle(isOffline ? .red : .green)
                Text(isOffline ? "Offline" : "Online")
                    .font(.body)
                    .foregroundStyle(isOffline ? .red : .green)
            }
        }
    }
}

// MARK: - Focusable Section Wrapper (tvOS focus indicator bar effect for section)

fileprivate struct FocusableSection<Header: View, Content: View, Footer: View>: View {
    @FocusState private var isFocused: Bool
    
    let header: Header
    let content: Content
    let footer: Footer
    
    init(@ViewBuilder header: () -> Header,
         @ViewBuilder content: () -> Content,
         @ViewBuilder footer: () -> Footer = { EmptyView() }) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
#if os(tvOS)
            // Focus indicator bar
            Rectangle()
                .fill(isFocused ? Color.primary : Color.clear)
                .padding(.top, SectionHeader.topPadding)
                .frame(width: 10)
#endif
            VStack(alignment: .leading, spacing: 4) {
                header
                content
                footer
            }
#if os(tvOS)
            .padding(.leading, leadingPadding)
#endif
        }
#if os(tvOS)
        .focusable()
        .focused($isFocused)
#endif
    }
}


// MARK: - Preview

#Preview("Light Mode") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let device = swiftDataController.homeRunDevices()[1]
    
    return TVPreviewView() {
        NavigationStack {
            DeviceDetailView(device: device)
        }
        .background(.clear)
#if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        .containerBackground(.clear, for: .navigation)
#endif
    }
    .environment(\.colorScheme, .light)
}


#Preview("Dark Mode") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let device = swiftDataController.homeRunDevices()[0]
    
    return TVPreviewView() {
        NavigationStack {
            DeviceDetailView(device: device)
        }
        .background(.clear)
#if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        .containerBackground(.clear, for: .navigation)
#endif
    }
    .environment(\.colorScheme, .dark)
}
