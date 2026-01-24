//
//  MainMenu.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/19/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct MainMenu: View {
    
    @Binding var appState: AppStateProvider
    
    @State private var swiftDataController: SwiftDataControllable = InjectedValues[\.swiftDataController]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Menu {
                    Picker("", selection: $appState.selectedTab) {
                        ForEach(AppSection.allCases) { tabSection in
                            Text(tabSection.title).tag(tabSection)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    
                    if appState.selectedTab == .guide {
                        Toggle(isOn:Binding(
                            get: { swiftDataController.showFavoritesOnly },
                            set: { swiftDataController.showFavoritesOnly = $0 }
                        )) {
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
            
            
            SectionView(appState: $appState)
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
    
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    MainMenu(appState: $appState)
}
