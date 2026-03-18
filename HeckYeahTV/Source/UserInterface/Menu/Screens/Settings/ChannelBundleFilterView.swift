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
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    
    @State private var showingDeleteConfirmation = false
    @State private var bundleNameBuffer: String = ""
    @State private var matchingChannelCount: Int = 0
    @State private var categories: [ProgramCategory] = []
    @State private var countries: [Country] = []
    
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
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Bundle", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
            } header: {
                Text("Bundle Settings")
                    .padding(.top, 20)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            // MARK: - Filter Section
            Section {
                // Search Term
                HStack {
                    Text("Search Term")
                    Spacer()
                    TextField("Channel name contains...",
                              text: Binding(
                                get: { swiftDataController.searchTerm ?? "" },
                                set: { swiftDataController.searchTerm = $0.isEmpty ? nil : $0 }
                              )
                    )
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
                }
                .foregroundStyle(.primary)
                
                // Country Picker
                NavigationLink {
                    CountryPickerView(
                        selectedCountry: Binding(
                            get: { swiftDataController.selectedCountry },
                            set: { swiftDataController.selectedCountry = $0 }
                        ),
                        countries: countries
                    )
                } label: {
                    HStack {
                        Text("Country")
                        Spacer()
                        Text(selectedCountryName)
                    }
                }

                // Category Picker
                NavigationLink {
                    CategoryPickerView(
                        selectedCategory: Binding(
                            get: { swiftDataController.selectedCategory },
                            set: { swiftDataController.selectedCategory = $0 }
                        ),
                        categories: categories
                    )
                } label: {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(selectedCategoryName)
                    }
                }
                
                // Clear Category Button (only show if category is selected)
                if swiftDataController.selectedCategory != nil {
                    Button {
                        swiftDataController.selectedCategory = nil
                    } label: {
                        Label("Clear Category", systemImage: "xmark.circle")
                    }
                    .foregroundStyle(.primary)
                }
                
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Channel Filters")
                        .padding(.top, 20)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Set filters to narrow down which channels to add to this bundle. Country filter is always applied.")
                        .fontWeight(.regular)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            
            // MARK: - Manage Channels Section
            Section {
                NavigationLink {
                    ChannelManagementView(bundle: bundle)
                } label: {
                    HStack {
                        Text("Filtered Channels")
                        Spacer()
                        if matchingChannelCount > 0 {
                            Text("\(matchingChannelCount) matching")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manage Channels")
                        .padding(.top, 20)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("View and add/remove channels from this bundle based on your current filters.")
                        .fontWeight(.regular)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
        }
#if os(iOS)
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
        .onChange(of: swiftDataController.searchTerm) { _, _ in
            Task { await updateMatchingCount() }
        }
        .onChange(of: swiftDataController.selectedCountry) { _, _ in
            Task { await updateMatchingCount() }
        }
        .onChange(of: swiftDataController.selectedCategory) { _, _ in
            Task { await updateMatchingCount() }
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
        
        await updateMatchingCount()
    }
    
    private func updateMatchingCount() async {
        let channels = swiftDataController.channelsForCurrentFilter()
        matchingChannelCount = channels.count
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    @Previewable @State var navigationPath: [SettingsDestination] = []
    @Previewable @FocusState var focusedField: Field?
    
    enum Field: Hashable {
        case bundleName
        case deleteButton
        case countryPicker
        case categoryPicker
        case clearCategory
        case manageChannels
    }
    
    InjectedValues[\.sharedAppState] = appState
    
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelBundle = swiftDataController.channelBundles().first!
    
    return TVPreviewView {
        NavigationStack(path: $navigationPath) {
            ChannelBundleFilterView(navigationPath: $navigationPath, bundle: channelBundle)
                .onAppear {
                    // Set initial focus to see focus styling in preview
                    focusedField = .countryPicker
                }
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
        }.background(.gray)
    }
    
    .environment(\.colorScheme, .dark)
}
