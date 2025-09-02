//
//  TVTabViewNavigation.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

#if os(tvOS)
struct TVTabViewNavigation<Content: View>: View {
    @Binding var selection: TabSection
    @ViewBuilder var content: () -> Content
    
    @FocusState private var focused: TabSection?
    
    var body: some View {
        
        TabView {
            ForEach(TabSection.allCases) { section in
                content()
//                    .ignoresSafeArea()
                    .tabItem { Label(section.title,
                                     systemImage: section.systemImage) }
                    .tag(section)
            }
        }
        //.tabViewStyle(.sidebarAdaptable)
        .background(.ultraThinMaterial)
    }
}
#endif
