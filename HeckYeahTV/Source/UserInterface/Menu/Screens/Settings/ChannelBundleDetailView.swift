//
//  ChannelBundleDetailView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/8/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct ChannelBundleDetailView: View {
    @Bindable var bundle: ChannelBundle
    
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var showingDeleteConfirmation = false
    @State private var canDelete: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var bundleNameBuffer: String = ""
    @State private var showingEmptyNameAlert = false
    @FocusState private var nameFieldFocused: Bool
    @State private var searchTerm: String = ""
    @State private var availableChannelCount: Int = 0
    @State private var categories: [ProgramCategory] = []
    @State private var countries: [Country] = []
    
    private var nameIsInvalid: Bool {
        bundleNameBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var filteredChannels: [Channel] {
        do {
            let channels = try swiftDataController.channelsForCurrentFilter()
            return channels
        } catch {
            logError("Error retrieving channels matching filter: \(error)")
            return []
        }
    }
    
    private func isChannelInBundle(_ channel: Channel) -> Bool {
        bundle.channels.contains { $0.channel?.id == channel.id }
    }
    
    var body: some View {
        List {
            // MARK: - Bundle Info Section
            Section {
                TextField("Bundle Name", text: $bundleNameBuffer)
                    .focused($nameFieldFocused)
                    .onSubmit { commitBundleName() }
                    .onChange(of: nameFieldFocused) { _, isFocused in
                        if !isFocused { commitBundleName() }
                    }
                
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: "trash")
                            .foregroundStyle(.blue)
                        
                        Text("Delete Bundle")
                            .font(.body)
                            .foregroundStyle(.red)
                    }
                }
                .disabled(!canDelete)
            } header: {
                Text("Bundle Settings")
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
#if !os(tvOS)
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
#endif
            
            
            // MARK: - Filters Section
            Section {
                TVNavigationLink {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(selectedCategoryName)
                            .foregroundStyle(.secondary)
                    }
                } destination: {
                    CategoryPickerView(
                        selectedCategory: Binding(
                            get: { swiftDataController.selectedCategory },
                            set: { swiftDataController.selectedCategory = $0 }
                        ),
                        categories: categories
                    )
                }
                
                TVNavigationLink {
                    HStack {
                        Text("Country")
                        Spacer()
                        Text(selectedCountryName)
                            .foregroundStyle(.secondary)
                    }
                } destination: {
                    CountryPickerView(
                        selectedCountry: Binding(
                            get: { swiftDataController.selectedCountry },
                            set: { swiftDataController.selectedCountry = $0 }
                        ),
                        countries: countries
                    )
                }
            } header: {
                Text("Channel Filters")
            } footer: {
                Text("Filter which channels appear in the list below.")
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
#if !os(tvOS)
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
#endif

            .disabled(nameIsInvalid)
            
            
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
                    Text("Available Channels")
                    Spacer()
                    Text("\(filteredChannels.count) of \(availableChannelCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.none)
                }
            } footer: {
                if filteredChannels.isEmpty == false {
                    Text("Tap channels to add or remove them from this bundle.")
                }
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(white: 0.1).opacity(0.8))
#if !os(tvOS)
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
#endif
            .disabled(nameIsInvalid)
        }
#if !os(tvOS)
        .scrollContentBackground(.hidden)
#endif
        
        .navigationTitle(bundle.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .searchable(text: $searchTerm, prompt: "Search channels")
        .onChange(of: searchTerm) { _, newValue in
            swiftDataController.searchTerm = newValue
        }
        #if os(iOS)
        .navigationBarBackButtonHidden(nameFieldFocused)
        #endif
        .alert("Bundle Name Required", isPresented: $showingEmptyNameAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The bundle name cannot be empty.")
        }
        .alert("Delete Channel Bundle", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteBundle()
            }
        } message: {
            Text("Are you sure you want to delete '\(bundle.name)'? This action cannot be undone.")
        }
        .task {
            bundleNameBuffer = bundle.name
            loadData()
        }
    }
    
    // MARK: - Computed Properties
    
    private var selectedCategoryName: String {
        guard let categoryId = swiftDataController.selectedCategory else {
            return "All Categories"
        }
        return categories.first(where: { $0.categoryId == categoryId })?.name ?? "Unknown"
    }
    
    private var selectedCountryName: String {
        let countryCode = swiftDataController.selectedCountry
        let country = countries.first(where: { $0.code == countryCode })
        if let country {
            return "\(country.flag) \(country.name)"
        }
        return "Unknown"
    }
    
    // MARK: - Actions
    
    private func commitBundleName() {
        let trimmed = bundleNameBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            nameFieldFocused = true
            showingEmptyNameAlert = true
        } else {
            bundle.name = trimmed
            bundleNameBuffer = trimmed
            nameFieldFocused = false
        }
    }
    
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
    
    private func deleteBundle() {
        guard canDelete else { return }
        swiftDataController.viewContext.delete(bundle)
        try? swiftDataController.viewContext.saveChangesIfNeeded()
        dismiss()
    }
    
    private func loadData() {
        availableChannelCount = (try? swiftDataController.totalChannelCount()) ?? 0
        categories = (try? swiftDataController.programCategories()) ?? []
        countries = (try? swiftDataController.countries()) ?? []
        
        // Check if this bundle can be deleted
        let totalBundles = (try? swiftDataController.channelBundles().count) ?? 0
        canDelete = totalBundles > 1
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
            ChannelBundleDetailView(bundle: channelBundle)
        }
    }
}
