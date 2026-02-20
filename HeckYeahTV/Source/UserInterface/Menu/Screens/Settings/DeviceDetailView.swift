import SwiftUI

struct DeviceDetailView: View {
    let device: HomeRunDevice
    @State private var isRefreshing = false
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {

                // MARK: - Settings Section
                SectionHeader("Settings")
                Toggle("Include Channel Line-up", isOn: Binding(
                    get: { device.includeChannelLineUp_Save },
                    set: { newValue in
                        device.includeChannelLineUp_Save = newValue
                    }
                ))
                .tint(.mainAppTheme)
                Text("When enabled, channels from this device will appear in the guide regardless of the selected channel bundle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // MARK: - Device Info Section
                SectionHeader("Device Information")
                DetailRow(label: "Name", value: device.friendlyName)
                DetailRow(label: "Model", value: device.modelNumber)
                DetailRow(label: "Device ID", value: device.deviceId)

                // MARK: - Firmware Section
                SectionHeader("Firmware")
                DetailRow(label: "Firmware Name", value: device.firmwareName)
                DetailRow(label: "Version", value: device.firmwareVersion)

                // MARK: - Network Section
                SectionHeader("Network")
                DetailRow(label: "Base URL", value: device.baseURL.absoluteString)
                DetailRow(label: "Lineup URL", value: device.lineupURL.absoluteString)

                // MARK: - Tuners Section
                SectionHeader("Tuners")
                DetailRow(label: "Tuner Count", value: "\(device.tunerCount)")
                let channelCount = swiftDataController.totalChannelCountFor(deviceId: device.deviceId)
                DetailRow(label: "Channel Count", value: "\(channelCount)")
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(.clear)
#if !os(tvOS)
        .scrollContentBackground(.hidden)
#endif
        .navigationTitle("Device Details")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onChange(of: device.includeChannelLineUp_Save) {
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

struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.top, 8)
    }
}

// MARK: - Detail Row Component

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
#if !os(tvOS)
                .textSelection(.enabled)
#endif
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
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
}
