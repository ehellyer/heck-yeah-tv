import SwiftUI

struct DeviceDetailView: View {
    let device: HomeRunDevice
    @State private var isRefreshing = false
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]    
    
    var body: some View {
        List {
            // MARK: - Device Info Section
            Section {
                DetailRow(label: "Name", value: device.friendlyName)
                DetailRow(label: "Model", value: device.modelNumber)
                DetailRow(label: "Device ID", value: device.deviceId)
            } header: {
                Text("Device Information")
            }
            
            // MARK: - Firmware Section
            Section {
                DetailRow(label: "Firmware Name", value: device.firmwareName)
                DetailRow(label: "Version", value: device.firmwareVersion)
            } header: {
                Text("Firmware")
            }
            
            // MARK: - Network Section
            Section {
                DetailRow(label: "Base URL", value: device.baseURL.absoluteString)
                DetailRow(label: "Lineup URL", value: device.lineupURL.absoluteString)
            } header: {
                Text("Network")
            }
            
            // MARK: - Tuners Section
            Section {
                HStack {
                    Text("Tuner Count")
                    Spacer()
                    Text("\(device.tunerCount)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Channel Count")
                    Spacer()
                    let channelCount = (try? swiftDataController.totalChannelCountFor(deviceId: device.deviceId)) ?? 0
                    Text("\(channelCount)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Tuners")
            }
            
            // MARK: - Actions Section
            Section {
                Button {
                    refreshDevice()
                } label: {
                    Label("Refresh Device", systemImage: "arrow.clockwise")
                }
                .foregroundStyle(.blue)
                .disabled(isRefreshing)
                
                Link(destination: device.baseURL) {
                    Label("Open Device Web Interface", systemImage: "safari")
                }
                .foregroundStyle(.blue)
                
                Link(destination: device.lineupURL) {
                    Label("View Channel Lineup", systemImage: "list.bullet")
                }
                .foregroundStyle(.blue)
            } header: {
                Text("Actions")
            }
        }
        .navigationTitle("Device Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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

// MARK: - Detail Row Component

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
    
    let device = try! swiftDataController.homeRunDevices().first!
    
    return TVPreviewView() {
        NavigationStack {
            DeviceDetailView(device: device)
        }
    }
}
