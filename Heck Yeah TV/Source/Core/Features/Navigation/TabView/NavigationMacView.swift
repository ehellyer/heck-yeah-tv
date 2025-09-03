//
//  NavigationMacView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

#if os(macOS)
struct NavigationMacView<Content: View>: View {
    @Binding var selectedTab: TabSection
    @ViewBuilder var contentView: () -> Content
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabSection.allCases) { tab in
                contentView()
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
    }
}


#Preview {
    
    NavigationMacView(selectedTab: .constant(.last)) {
        Text("Content goes here")
    }
}
#endif
