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
        VStack(spacing: 0) {
            HStack {
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
                
                Spacer()
                
                Button("Done") {
                    withAnimation {
                        appState.showAppMenu = false
                    }
                }
                .buttonStyle(.automatic)
                .tint(.white)
            }
            .overlay {
                Text(appState.selectedTab.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            .foregroundStyle(.white)
            .background(.ultraThinMaterial)
            .zIndex(1)
            
            // Selected Menu Content
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            
#if os(macOS)
                .padding()
#endif
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.guideTransparency)
        }
        .transition(
            .move(edge: .bottom)
            .combined(with: .opacity)
        )
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
    
    return MenuPickerView()
}
