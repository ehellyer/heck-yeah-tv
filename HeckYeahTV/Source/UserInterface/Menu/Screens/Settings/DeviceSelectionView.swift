//
//  DeviceSelectionView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/19/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct DeviceSelectionView: View {
    
    @Bindable var bundle: ChannelBundle
    
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    @State private var devices: [HomeRunDevice] = []
    
    var body: some View {
        List {
            Section {
                if enabledDevices.isEmpty {
                    Text("No enabled devices found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(enabledDevices, id: \.deviceId) { device in
                        DeviceRow(
                            device: device,
                            isAssociated: swiftDataController.isDeviceAssociated(device: device, with: bundle),
                            onToggle: {
                                toggleDevice(device)
                            }
                        )
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HDHomeRun Devices")
                        .padding(.top, 20)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Select a device to include its channel lineup in the channel bundle.")
                        .fontWeight(.regular)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.bottom, 20)
                }
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#endif
        .navigationTitle("HDHomeRun Device Selection")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            await loadDevices()
        }
    }
    
    // MARK: - Computed Properties
    
    private var enabledDevices: [HomeRunDevice] {
        devices.filter { $0.isEnabled }
    }
    
    // MARK: - Actions
    
    private func loadDevices() async {
        devices = swiftDataController.homeRunDevices()
    }
    
    private func toggleDevice(_ device: HomeRunDevice) {
        let isCurrentlyAssociated = swiftDataController.isDeviceAssociated(device: device, with: bundle)
        
        if isCurrentlyAssociated {
            swiftDataController.removeDeviceFromBundle(device: device, bundle: bundle)
        } else {
            swiftDataController.addDeviceToBundle(device: device, bundle: bundle)
        }
    }
}

// MARK: - Device Row Component

fileprivate struct DeviceRow: View {
    let device: HomeRunDevice
    let isAssociated: Bool
    let onToggle: () -> Void
    
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.friendlyName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text("\(channelCount) channels")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                
                
                Image(systemName: isAssociated ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isAssociated ? .blue : .secondary)
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
                
                //#if os(tvOS)
                //                // tvOS: Show checkmark when selected
                //                if isAssociated {
                //                    Image(systemName: "checkmark.circle.fill")
                //                        .foregroundStyle(.green)
                //                } else {
                //                    Image(systemName: "circle")
                //                        .foregroundStyle(.secondary)
                //                }
                //#else
                //                // iOS/macOS: Use Toggle
                //                Toggle("", isOn: .constant(isAssociated))
                //                    .labelsHidden()
                //                    .allowsHitTesting(false)
                //#endif
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
    
    private var channelCount: Int {
        swiftDataController.channelCountFor(deviceId: device.deviceId)
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
    
    let bundle = swiftDataController.channelBundles()[0]
    
    return TVPreviewView() {
        NavigationStack {
            DeviceSelectionView(bundle: bundle)
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
    
    let bundle = swiftDataController.channelBundles()[0]
    
    return TVPreviewView() {
        NavigationStack {
            DeviceSelectionView(bundle: bundle)
        }
        .background(.clear)
#if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        .containerBackground(.clear, for: .navigation)
#endif
    }
    .environment(\.colorScheme, .dark)
}
