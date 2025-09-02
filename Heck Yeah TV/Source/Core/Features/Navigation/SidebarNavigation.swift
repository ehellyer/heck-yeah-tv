//
//  SidebarNavigation.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

#if os(macOS)
struct SidebarNavigation<Content: View>: View {
    @Binding var selection: TabSection
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        NavigationSplitView {
            List() {
                ForEach(TabSection.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .tag(section)
                }
            }
            .navigationTitle("Heck Yeah TV")
        } detail: {
            content()
                .navigationTitle(selection.title)
        }
    }
}
#endif

//#Preview {
//    
//    
//    
//    SidebarNavigation(selection: .last) {
//        
//    }
//}
