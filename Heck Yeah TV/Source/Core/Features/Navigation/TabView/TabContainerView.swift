//
//  TabContainerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct TabContainerView: View {
    
    @Environment(GuideStore.self) var guideStore
    @FocusState var focus: FocusTarget?
    
    private var selectedTab: Binding<TabSection> {
        Binding(
            get: {
                guideStore.selectedTab
            },
            set: {
                guideStore.selectedTab = $0
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Focus: \(focus?.debugDescription ?? "nil") | Tab: \(selectedTab.wrappedValue.title) | selected channel: \(guideStore.selectedChannel?.title ?? "none") ")
                .fontWeight(.bold)
                .background(Color(.gray))
            
            TabView(selection: selectedTab) {
                
                Tab(TabSection.recents.title,
                    systemImage: TabSection.recents.systemImage,
                    value: TabSection.recents) {
                    RecentsView()
                }
                
                Tab(TabSection.channels.title,
                    systemImage: TabSection.channels.systemImage,
                    value: TabSection.channels) {
                    ChannelsContainer(focus: $focus)
                }
                
                Tab(TabSection.search.title,
                    systemImage: TabSection.search.systemImage,
                    value: TabSection.search) {
                    SearchView()
                }
                
                Tab(TabSection.settings.title,
                    systemImage: TabSection.settings.systemImage,
                    value: TabSection.settings) {
                    SettingsView()
                }
            }
            .padding()
            .background(Color.clear)

            .onChange(of: focus) {
                DispatchQueue.main.async {
                    print("<<< Focus onChange: \(self.focus?.debugDescription ?? "nil")")
                }
            }
            
#if !os(iOS)
            // Support for dismissing the tabview by tapping menu on Siri remote for tvOS or esc key on keyboard.
            .onExitCommand {
                withAnimation(.easeOut(duration: 0.25)) {
                    guideStore.isGuideVisible = false
                }
            }
#endif // !os(iOS)
            
#if !os(iOS)
//            .onMoveCommand { direction in
//                handleOnMoveCommand(direction)
//            }
#endif
        }
    }
    
#if !os(iOS)
    
//    private func handleOnMoveCommand(_ direction: MoveCommandDirection) {
//        print(">>> func handleOnMoveCommand(_ direction: \(direction)), FocusTarget: \(self.focus?.debugDescription ?? "unknown"), ")
//        
//        switch (self.focus, direction) {
//
//            case (.guide(let id, _), .up):
//                if guideStore.visibleChannels.first?.id == id {
//                    lastGuideFocusedTarget = focus
//                    withAnimation {
//                        focus = .favoritesToggle
//                    }
//                }
//
//            case (.favoritesToggle, .right),
//                (.favoritesToggle, .left),
//                (.favoritesToggle, .down):
//
//                // from Favorites to guide when either <LEFT> or <RIGHT> on favorites toggle.
//                withAnimation {
//                    if let channelId = guideStore.visibleChannels.first?.id {
//                        focus = FocusTarget.guide(channelId: channelId, col: 1)
//                    }
//                }
//
//            case (.guide(_, let col), .left):
//                // from guide channel col <LEFT> to favorites
//                if col == 1 {
//                    lastGuideFocusedTarget = focus
//                    withAnimation {
//                        focus = .favoritesToggle
//                    }
//                }
//            default:
//                break
//        }
//    }
#endif // !os(iOS)
}

// MARK: - Previews

#if DEBUG && targetEnvironment(simulator)
private struct PreviewTabContainerView: View {
    
    @State private var guideStore = GuideStore()
    
    var body: some View {
        VStack {
            TabContainerView()
                .environment(guideStore)
                .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    PreviewTabContainerView()
        .ignoresSafeArea(.all)
}
#endif // DEBUG && targetEnvironment(simulator)
