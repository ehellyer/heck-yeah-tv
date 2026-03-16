//
//  ChannelManagementView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/14/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

/// Screen for adding/removing channels from a bundle based on current filter criteria
struct ChannelManagementView: View {
    
    @Bindable var bundle: ChannelBundle
    @Bindable var channelFilters: ChannelBundleFilterViewModel
    
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var filteredChannels: [Channel] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading channels...")
            } else if filteredChannels.isEmpty {
                ContentUnavailableView(
                    "No Channels Found",
                    systemImage: "tv.slash",
                    description: Text("Try adjusting your filter criteria")
                )
            } else {
                channelList
            }
        }
        .navigationTitle("Manage Channels")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            await loadChannels()
        }
        .onChange(of: channelFilters.searchTerm) { _, _ in
            Task {
                await loadChannels()
            }
        }
        .onChange(of: channelFilters.selectedCountry) { _, _ in
            Task {
                await loadChannels()
            }
        }
        .onChange(of: channelFilters.selectedCategory) { _, _ in
            Task {
                await loadChannels()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var channelList: some View {
        List {
            Section {
                ForEach(filteredChannels) { channel in
                    //channelRow(for: channel)
                    ChannelRow(channel: channel,
                               isInBundle: isChannelInBundle(channel)) {
                        toggleChannel(channel)
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(filteredChannels.count) channels")
                        .foregroundStyle(.white)
                    Text("Tap a channel to add or remove it from this bundle")
                        .foregroundStyle(.secondary)

                }
            }
        }
        
#if os(tvOS)
        .clipped()
#endif
#if os(iOS)
        .listStyle(.insetGrouped)
#endif
    }
    
    // MARK: - Helper Methods
    
    private func isChannelInBundle(_ channel: Channel) -> Bool {
        bundle.channels.contains { $0.channel?.id == channel.id }
    }
    
    private func toggleChannel(_ channel: Channel) {
        if let existingEntry = bundle.channels.first(where: { $0.channel?.id == channel.id }) {
            // Remove from bundle
            bundle.channels.removeAll { $0.id == existingEntry.id }
            swiftDataController.viewContext.delete(existingEntry)
        } else {
            // Add to bundle
            let bundleEntry = BundleEntry(
                channel: channel,
                channelBundle: bundle,
                sortHint: channel.sortHint,
                isFavorite: false
            )
            swiftDataController.viewContext.insert(bundleEntry)
            bundle.channels.append(bundleEntry)
        }
        
        // Save changes
        if swiftDataController.viewContext.hasChanges {
            try? swiftDataController.viewContext.save()
            swiftDataController.invalidateChannelBundleMap()
        }
    }
    
    private func loadChannels() async {
        isLoading = true
        
        // Apply filters to SwiftDataController temporarily
        let previousSearchTerm = swiftDataController.searchTerm
        let previousCountry = swiftDataController.selectedCountry
        let previousCategory = swiftDataController.selectedCategory
        
        swiftDataController.searchTerm = channelFilters.trimmedSearchTerm
        swiftDataController.selectedCountry = channelFilters.selectedCountry
        swiftDataController.selectedCategory = channelFilters.selectedCategory
        
        // Fetch filtered channels
        filteredChannels = swiftDataController.channelsForCurrentFilter()
        
        // Restore previous filter state
        swiftDataController.searchTerm = previousSearchTerm
        swiftDataController.selectedCountry = previousCountry
        swiftDataController.selectedCategory = previousCategory
        
        isLoading = false
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    let appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelBundle = swiftDataController.channelBundles().first!
    let channelFilters = ChannelBundleFilterViewModel()
    
    return TVPreviewView {
        NavigationStack {
            ChannelManagementView(bundle: channelBundle, channelFilters: channelFilters)
        }
    }
    .environment(\.colorScheme, .light)
}

#Preview("Dark Mode") {
    let appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelBundle = swiftDataController.channelBundles().first!
    let channelFilters = ChannelBundleFilterViewModel()
    
    return TVPreviewView {
        NavigationStack {
            ChannelManagementView(bundle: channelBundle, channelFilters: channelFilters)
        }
    }
    .environment(\.colorScheme, .dark)
}
