//
//  TabBarNavigation.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

#if os(iOS)
struct TabBarNavigation<Content: View>: View {
    @Binding var selection: TabSection
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(TabSection.allCases) { section in
                contentView(section)
                    .tabItem { Label(section.title, systemImage: section.systemImage) }
                    .tag(section)
            }
        }
    }
    
    @ViewBuilder
    private func contentView(_ section: TabSection) -> some View {
        if section == selection { content() } else { Color.clear }
    }
}
#endif
