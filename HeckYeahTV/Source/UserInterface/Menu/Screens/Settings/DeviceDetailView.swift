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
    
    @State private var isRefreshing = false
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]

    var body: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 4) {
                
                // MARK: - Settings Section
                Section {
                    Button(action: {
                        device.isEnabled.toggle()
                    }) {
                        HStack(spacing: 20) {
                            Text("Enable for Heck Yeah TV")
                            Text(device.isEnabled ? "Yes" : "No")
                        }
                        .foregroundStyle(.primary)
                        
                    }
                    .buttonStyle(.glass)
                    
                    
                } header: {
                    SectionHeader("Settings")
                } footer: {
                    Text("When enabled, channels from this device will be available to be included in a channel bundle.  Edit a channel bundle to include this devices channel line up.")
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
#endif
        .navigationTitle("Tuner Details")
#if !os(tvOS)
        .scrollContentBackground(.hidden)
#endif

#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .background(.clear)
        .onChange(of: device.isEnabled) {
            swiftDataController.invalidateTunerLineUp()
        }
    }

    
    // MARK: - Actions
    
    private func refreshDevice() {
        isRefreshing = true
        // TODO: Implement device refresh logic
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                isRefreshing = false
            }
        }
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
    .environment(\.colorScheme, .dark)
}
