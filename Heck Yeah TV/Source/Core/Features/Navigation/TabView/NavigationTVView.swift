//
//  NavigationTVView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

#if os(tvOS)
struct NavigationTVView<Content: View>: View {
    @Binding var selectedTab: TabSection
    @ViewBuilder var contentView: () -> Content
    
    @FocusState private var focused: TabSection?
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            ForEach(TabSection.allCases) { tab in
                
                    VStack {
                        contentView()
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 20)
                
                .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                .tag(tab)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationTVView(selectedTab: .constant(.recents)) {
        Text("Content goes here")
    }
}

#endif
