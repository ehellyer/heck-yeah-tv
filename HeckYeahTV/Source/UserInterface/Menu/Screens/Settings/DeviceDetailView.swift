import SwiftUI


// MARK: - Focusable Section Wrapper (tvOS focus indicator bar effect for section)

struct FocusableSection<Header: View, Content: View, Footer: View>: View {
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
            .padding(.leading, DeviceDetailView.leadingPadding)
#endif
        }
#if os(tvOS)
        .focusable()
        .focused($isFocused)
#endif
    }
}


struct DeviceDetailView: View {
    let device: HomeRunDevice
    @State private var isRefreshing = false
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    
    static let leadingPadding: CGFloat = 8
    
    
    var body: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 4) {
                
                // MARK: - Settings Section
                Section {
                    Button(action: {
                        device.includeChannelLineUp_Save.toggle()
                    }) {
                        HStack(alignment: .center) {
                            Text("Include Channel Line-up")
                            Text(device.includeChannelLineUp_Save ? "Yes" : "No")
                        }
                    }
                    .buttonStyle(.glass)
                    
                } header: {
                    SectionHeader("Settings")
                } footer: {
                    Text("When enabled, channels from this device will appear in the guide regardless of the selected channel bundle.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
#if os(tvOS)
                .padding(.leading, DeviceDetailView.leadingPadding)
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
        }
        .contentMargins(10, for: .scrollContent)
        .scrollClipDisabled()
        .navigationTitle("Tuner Details")
        .background(.clear)

#if !os(tvOS)
        .scrollContentBackground(.hidden)
#endif

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

    static let topPadding: CGFloat = 30
    
    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .padding(.top, SectionHeader.topPadding)
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
        }
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
