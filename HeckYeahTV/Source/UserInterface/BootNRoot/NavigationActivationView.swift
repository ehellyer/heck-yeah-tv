//
//  NavigationActivationView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/26/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NavigationActivationView: View {

    @Binding var appState: AppStateProvider
    
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity) // fill parent
            .accessibilityHidden(true)
            .focusable(true, interactions: .activate)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    appState.showAppNavigation = true
                }
            }
    }
}
