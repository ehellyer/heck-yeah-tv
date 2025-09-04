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
    @FocusState private var focus: FocusTarget?
    
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
        .onMoveCommand(perform: handleMoveCommand)
    }
    
    private func handleMoveCommand(_ dir: MoveCommandDirection) {
        guard let f = focus else { return }
        switch (f, dir) {
            case (.guide(let r, _), .up):
                if r == 0 {
                    // leaving guide upward -> header
                    focus = .favoritesToggle
                }
            case (.favoritesToggle, .up):
                // leaving header upward -> tabs (selected)
                focus = .tab(selectedTab)
            case (.favoritesToggle, .down):
                // back into guide, same column 0
                focus = .guide(row: 0, col: 0)
            case (.tab, .down):
                // from tabs to header
                focus = .favoritesToggle
            default:
                break
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
