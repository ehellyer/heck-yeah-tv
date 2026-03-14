//
//  ChannelBundleFilterView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/13/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelBundleFilterView: View {
    
    @Binding var navigationPath: [SettingsDestination]
    @Bindable var bundle: ChannelBundle
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var viewModel: ChannelBundleFilterViewModel
    
    @State private var showingDeleteConfirmation = false
    @State private var bundleNameBuffer: String = ""
    @State private var matchingChannelCount: Int = 0
    @State private var categories: [ProgramCategory] = []
    @State private var countries: [Country] = []
    
    init(navigationPath: Binding<[SettingsDestination]>, bundle: ChannelBundle) {
        self._navigationPath = navigationPath
        self.bundle = bundle
        // Initialize view model with default country
        self._viewModel = State(initialValue: ChannelBundleFilterViewModel())
    }
    
    var body: some View {
        List {
            // MARK: - Bundle Name & Delete Section
            Section {
#if os(tvOS)
                // tvOS: Navigate to dedicated text edit screen
                NavigationLink {
                    BundleNameEditView(bundleName: $bundleNameBuffer)
                } label: {
                    HStack {
                        Text("Bundle Name")
                        Spacer()
                        Text(bundleNameBuffer)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.primary)
                }
#else
                // iOS/macOS: Inline text field
                HStack {
                    Text("Bundle Name")
                        .foregroundStyle(.primary)
                    TextField("Bundle Name", text: $bundleNameBuffer)
                        .multilineTextAlignment(.trailing)
                        .onSubmit { commitBundleName() }
                }
#endif
                
                if canDelete {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Bundle", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Bundle Settings")
                    .foregroundStyle(.white)
            }
            
            // MARK: - Filter Section
            Section {
                // Search Term
                HStack {
                    Text("Search")
                    TextField("Channel name...", text: $viewModel.searchTerm)
                        .multilineTextAlignment(.trailing)
                }
                .foregroundStyle(.primary)
                
                // Country Picker
                TVNavigationLink {
                    HStack {
                        Text("Country")
                        Spacer()
                        Text(selectedCountryName)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                } destination: {
                    CountryPickerView(
                        selectedCountry: $viewModel.selectedCountry,
                        countries: countries
                    )
                }
                
                // Category Picker
                TVNavigationLink {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(selectedCategoryName)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                } destination: {
                    CategoryPickerView(
                        selectedCategory: $viewModel.selectedCategory,
                        categories: categories
                    )
                }
                
                // Clear Category Button (only show if category is selected)
                if viewModel.selectedCategory != nil {
                    Button {
                        viewModel.selectedCategory = nil
                    } label: {
                        Label("Clear Category", systemImage: "xmark.circle")
                    }
                    .foregroundStyle(.primary)
                }
                
            } header: {
                Text("Channel Filters")
                    .foregroundStyle(.white)
            } footer: {
                Text("Set filters to narrow down which channels to add to this bundle. Country filter is always applied.")
                    .foregroundStyle(.white)
            }
            
            // MARK: - Manage Channels Section
            Section {
                NavigationLink {
                    ChannelManagementView(bundle: bundle, viewModel: viewModel)
                } label: {
                    HStack {
                        Text("Manage Channels")
                        Spacer()
                        if matchingChannelCount > 0 {
                            Text("\(matchingChannelCount) matching")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            } footer: {
                Text("View and add/remove channels from this bundle based on your current filters.")
                    .foregroundStyle(.white)
            }
        }
#if !os(tvOS)
        .listStyle(.insetGrouped)
#endif
        .navigationTitle("Bundle Details")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    commitBundleName()
                    navigationPath.removeAll()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Settings")
                    }
                }
            }
        }
#endif
        .confirmationDialog(
            "Delete '\(bundle.name)'?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Bundle", role: .destructive) {
                deleteBundle()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All channel assignments in this bundle will be removed.")
        }
        .task {
            bundleNameBuffer = bundle.name
            await loadData()
        }
        .onChange(of: bundleNameBuffer) { _, _ in
            commitBundleName()
        }
        .onChange(of: viewModel.searchTerm) { _, _ in
            Task { await updateMatchingCount() }
        }
        .onChange(of: viewModel.selectedCountry) { _, _ in
            Task { await updateMatchingCount() }
        }
        .onChange(of: viewModel.selectedCategory) { _, _ in
            Task { await updateMatchingCount() }
        }
    }
    
    // MARK: - Computed Properties
    
    private var selectedCategoryName: String {
        guard let categoryId = viewModel.selectedCategory else {
            return "All Categories"
        }
        return categories.first(where: { $0.categoryId == categoryId })?.name ?? "Unknown"
    }
    
    private var selectedCountryName: String {
        let countryCode = viewModel.selectedCountry
        let country = countries.first(where: { $0.code == countryCode })
        if let country {
            return "\(country.flag) \(country.name)"
        }
        return "Unknown"
    }
    
    private var canDelete: Bool {
        let totalBundles = swiftDataController.channelBundles().count
        return totalBundles > 1
    }
    
    // MARK: - Actions
    
    private func commitBundleName() {
        let trimmed = bundleNameBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != bundle.name {
            bundle.name = trimmed
            bundleNameBuffer = trimmed
            try? swiftDataController.viewContext.saveChangesIfNeeded()
        }
    }
    
    private func deleteBundle() {
        guard canDelete else { return }
        
        swiftDataController.viewContext.delete(bundle)
        let channelBundles = swiftDataController.channelBundles()
        try? swiftDataController.viewContext.saveChangesIfNeeded()
        
        // Select first remaining bundle
        if let bundleId = channelBundles.first?.id {
            appState.selectedChannelBundleId = bundleId
        }
        
        navigationPath.removeAll()
    }
    
    private func loadData() async {
        categories = swiftDataController.programCategories()
        countries = swiftDataController.countries()
        
        // Reset view model to defaults
        viewModel.resetToDefaults()
        
        await updateMatchingCount()
    }
    
    private func updateMatchingCount() async {
        // Temporarily apply filters to get matching count
        let previousSearchTerm = swiftDataController.searchTerm
        let previousCountry = swiftDataController.selectedCountry
        let previousCategory = swiftDataController.selectedCategory
        
        swiftDataController.searchTerm = viewModel.trimmedSearchTerm
        swiftDataController.selectedCountry = viewModel.selectedCountry
        swiftDataController.selectedCategory = viewModel.selectedCategory
        
        let channels = swiftDataController.channelsForCurrentFilter()
        matchingChannelCount = channels.count
        
        // Restore previous state
        swiftDataController.searchTerm = previousSearchTerm
        swiftDataController.selectedCountry = previousCountry
        swiftDataController.selectedCategory = previousCategory
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    @Previewable @State var navigationPath: [SettingsDestination] = []
    
    InjectedValues[\.sharedAppState] = appState
    
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelBundle = swiftDataController.channelBundles().first!
    
    return TVPreviewView {
        NavigationStack(path: $navigationPath) {
            ChannelBundleFilterView(navigationPath: $navigationPath, bundle: channelBundle)
        }
    }
    .environment(\.colorScheme, .light)
}

#Preview("Dark Mode") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    @Previewable @State var navigationPath: [SettingsDestination] = []
    
    InjectedValues[\.sharedAppState] = appState
    
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelBundle = swiftDataController.channelBundles().first!
    
    return TVPreviewView {
        NavigationStack(path: $navigationPath) {
            ChannelBundleFilterView(navigationPath: $navigationPath, bundle: channelBundle)
        }
    }
    .environment(\.colorScheme, .dark)
}
