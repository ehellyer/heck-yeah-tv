//
//  ChannelsContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct ChannelsContainer: View {
    
    // Private
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var focusCoordinator: GuideFocusCoordinator = GuideFocusCoordinator()
    
    @Namespace private var focusNamespace
    @FocusState private var focusedField: FocusField?
    @FocusState private var isGuideFocused: Bool
    
    enum FocusField: Hashable {
        case showFavorites
        case guide
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ShowFavorites(
                focusNamespace: focusNamespace,
                focusedField: $focusedField
            )
            .padding(.bottom, 10)
            
            GuideViewRepresentable(isFocused: $isGuideFocused)
                .focused($focusedField, equals: .guide)
                .onAppear {
                    focusedField = .guide
                    isGuideFocused = true
                }
        }
        .background(Color.clear)
        .onChange(of: focusedField) { _, newValue in
            // Sync the guide focus state with our enum
            isGuideFocused = (newValue == .guide)
        }
        .onChange(of: focusCoordinator.shouldFocusShowFavorites) { _, shouldFocus in
            if shouldFocus {
                focusedField = .showFavorites
            }
        }
        .task {
            // Inject the coordinator so UIKit can access it
            InjectedValues[\.guideFocusCoordinator] = focusCoordinator
        }
    }
}

#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        ChannelsContainer()
    }
}
