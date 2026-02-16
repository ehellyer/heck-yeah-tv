import SwiftUI

struct DeviceDetailView: View {
    let device: HomeRunDevice
    @State private var isRefreshing = false
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]    
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // MARK: - Device Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Device Information")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    DetailRow(label: "Name", value: device.friendlyName)
                    DetailRow(label: "Model", value: device.modelNumber)
                    DetailRow(label: "Device ID", value: device.deviceId)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                #if !os(tvOS)
                .background(.clear)
                .cornerRadius(8)
                #endif
                
                // MARK: - Firmware Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Firmware")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    DetailRow(label: "Firmware Name", value: device.firmwareName)
                    DetailRow(label: "Version", value: device.firmwareVersion)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                #if !os(tvOS)
                .background(.clear)
                .cornerRadius(8)
                #endif
                
                // MARK: - Network Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Network")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    DetailRow(label: "Base URL", value: device.baseURL.absoluteString)
                    DetailRow(label: "Lineup URL", value: device.lineupURL.absoluteString)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                #if !os(tvOS)
                .background(Color.clear)
                .cornerRadius(8)
                #endif
                
                // MARK: - Tuners Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tuners")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
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
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                //#if !os(tvOS)
                .background(Color.clear)
                .cornerRadius(8)
//                #endif
                
//                // MARK: - Actions Section
//                VStack(alignment: .leading, spacing: 12) {
//                    Text("Actions")
//                        .font(.headline)
//                        .padding(.bottom, 4)
//                    
//                    Button {
//                        refreshDevice()
//                    } label: {
//                        Label("Refresh Device", systemImage: "arrow.clockwise")
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    #if os(tvOS)
//                    .buttonStyle(.card)
//                    #else
//                    .buttonStyle(.plain)
//                    #endif
//                    .foregroundStyle(.blue)
//                    .disabled(isRefreshing)
//                    
//                    Button {
//                        let url = device.baseURL
//#if os(macOS)
//                        NSWorkspace.shared.open(url)
//#else
//                        UIApplication.shared.open(url)
//#endif
//                    } label: {
//                        Label("Open Device Web Interface", systemImage: "safari")
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    #if os(tvOS)
//                    .buttonStyle(.card)
//                    #else
//                    .buttonStyle(.plain)
//                    #endif
//                    .foregroundStyle(.blue)
//                    
//                    Button {
//                        let url = device.lineupURL
//#if os(macOS)
//                        NSWorkspace.shared.open(url)
//#else
//                        UIApplication.shared.open(url)
//#endif
//                        
//                    } label: {
//                        Label("View Channel Lineup", systemImage: "list.bullet")
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    #if os(tvOS)
//                    .buttonStyle(.card)
//                    #else
//                    .buttonStyle(.plain)
//                    #endif
//                    .foregroundStyle(.blue)
//                }
//                .padding()
//                .frame(maxWidth: .infinity, alignment: .leading)
//                #if !os(tvOS)
//                .background(.clear)
//                .cornerRadius(8)
//                #endif
            }
            .padding()
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
