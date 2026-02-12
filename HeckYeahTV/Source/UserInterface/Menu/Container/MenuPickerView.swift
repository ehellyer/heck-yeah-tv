//
//  MenuPickerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/19/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct MenuPickerView: View {
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    
    var body: some View {
        NavigationStack {
            
            VStack(spacing: 0) {
                
                // Present the selected Menu content
                Group {
                    switch appState.selectedTab {
                        case .playerControls:
                            PlayerOverlay()
                        case .guide:
                            GuideView()
                        case .recents:
                            RecentsView()
                        case .settings:
                            SettingsContainerView()
                    }
                }
                .background(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
#if os(macOS)
                .padding()
#endif
            }
            .navigationTitle(appState.selectedTab.title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Menu {
                        //Menu items.
                        Picker("", selection: $appState.selectedTab) {
                            ForEach(AppSection.allCases) { tabSection in
                                Text(tabSection.title).tag(tabSection)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                        
                        // Add Show Favorites for Guide selection.
                        if appState.selectedTab == .guide {
                            Toggle(isOn:
                                    Binding(
                                        get: { swiftDataController.showFavoritesOnly },
                                        set: { swiftDataController.showFavoritesOnly = $0 })
                            ) {
                                Label("Favorites only", systemImage: "star.fill")
                                    .tint(Color.yellow)
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    } label: {
                        Label("Menu", systemImage: "slider.horizontal.3")
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.automatic)
                    .tint(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        withAnimation {
                            appState.showAppMenu = false
                        }
                    }
                    .buttonStyle(.automatic)
                    .tint(.white)
                }
            }
        }
#if !os(macOS)
        .toolbarBackground(.hidden, for: .navigationBar)
#endif
        .background(.clear)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    appState.selectedTab = .guide
    return TVPreviewView() {
        MenuPickerView()
    }
}
