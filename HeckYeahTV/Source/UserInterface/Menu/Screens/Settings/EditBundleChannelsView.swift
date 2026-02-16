import SwiftUI
import SwiftData

struct EditBundleChannelsView: View {
    @Bindable var bundle: ChannelBundle
    
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
    @State private var searchTerm: String = ""
    @State private var availableChannelCount: Int = 0
    @State private var categories: [ProgramCategory] = []
    @State private var countries: [Country] = []
    
    private var filteredChannels: [Channel] {
        let channels = try! swiftDataController.channelsForCurrentFilter()
        return channels
    }
    
    private func isChannelInBundle(_ channel: Channel) -> Bool {
        bundle.channels.contains { $0.channel?.id == channel.id }
    }
    
    var body: some View {
        List {
            // MARK: - Filters Section
            Section {
                Picker("Category", selection: $swiftDataController.selectedCategory) {
                    Text("All Categories").tag(nil as String?)
                        .foregroundStyle(.secondary)
                    
                    ForEach(categories, id: \.self) { category in
                        Text(category.name).tag(category.categoryId)
                            .foregroundStyle(.secondary)
                    }
                }
                
                
                Picker("Country", selection: $swiftDataController.selectedCountry) {
                    Text("All Countries").tag(nil as String?)
                    ForEach(countries, id: \.self) { country in
                        Text("\(country.flag) \(country.name)").tag(country.code)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Filters")
            }
            
            // MARK: - Channels Section
            Section {
                if filteredChannels.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tv.slash")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No channels found")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    ForEach(filteredChannels) { channel in
                        ChannelRow(
                            channel: channel,
                            isInBundle: isChannelInBundle(channel),
                            onToggle: {
                                toggleChannel(channel)
                            }
                        )
                    }
                }
            } header: {
                HStack {
                    Text("Channels")
                    Spacer()
                    Text("\(filteredChannels.count) of \(availableChannelCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.none)
                }
            }
        }
        .navigationTitle(bundle.name)
        .searchable(text: $searchTerm, prompt: "Search channels")
        .onChange(of: searchTerm) { _, newValue in
            swiftDataController.searchTerm = newValue
        }
        .task {
            loadLookupData()
        }
    }
    
    // MARK: - Actions
    
    private func toggleChannel(_ channel: Channel) {
        if let existingEntry = bundle.channels.first(where: { $0.channel?.id == channel.id }) {
            bundle.channels.removeAll { $0.id == existingEntry.id }
            swiftDataController.viewContext.delete(existingEntry)
        } else {
            let bundleEntry = BundleEntry(channel: channel,
                                          channelBundle: bundle,
                                          sortHint: channel.sortHint,
                                          isFavorite: false)
            swiftDataController.viewContext.insert(bundleEntry)
            bundle.channels.append(bundleEntry)
        }
        
        if swiftDataController.viewContext.hasChanges {
            try? swiftDataController.viewContext.save()
            swiftDataController.invalidateChannelBundleMap()
        }
    }
    
    private func loadLookupData() {
        availableChannelCount = (try? swiftDataController.totalChannelCount()) ?? 0
        categories = (try? swiftDataController.programCategories()) ?? []
        countries = (try? swiftDataController.countries()) ?? []
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
    
    let channelBundle = try! swiftDataController.channelBundles().first!
    
    return TVPreviewView() {
        NavigationStack {
            EditBundleChannelsView(bundle: channelBundle)
        }
    }
}
