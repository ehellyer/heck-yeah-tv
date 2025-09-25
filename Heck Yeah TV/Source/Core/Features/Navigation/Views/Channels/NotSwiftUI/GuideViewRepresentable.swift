//
//  GuideViewRepresentable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

@MainActor
struct GuideViewRepresentable: UnifiedPlatformControllerRepresentable {
    
    //MARK: - Bound State
    
    @Environment(GuideStore.self) var guideStore
    @FocusState.Binding var focus: FocusTarget?
    
    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        return context.coordinator.guideControllerView
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {
        context.coordinator.guideControllerView.updateView(channels: guideStore.visibleChannels, channelPrograms: [])
    }
    
    static func dismantleViewController(_ viewController: PlatformViewController, coordinator: Coordinator) {
        coordinator.guideControllerView.delegate = nil
        coordinator.guideControllerView.view.removeFromSuperview()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(
            setChannel: {
                guideStore.selectedChannel = $0
            },
            setFocus: {
                self.focus = $0
            },
            toggleFavorite: {
                guideStore.toggleFavorite($0)
            },
            isSelectedChannel: {
                guideStore.selectedChannel == $0
            },
            isFavorite: {
                guideStore.isFavorite($0)
            })
    }
    
    //MARK: - ViewControllerRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject  {
        
        private let setChannel: (GuideChannel) -> Void
        private let setFocus: (FocusTarget) -> Void
        private let toggleFavorite: (GuideChannel) -> Void
        private let isSelectedChannel: (GuideChannel) -> Bool
        private let isFavorite: (GuideChannel) -> Bool
        
        lazy var guideControllerView: GuideViewController = {
            let vc = GuideViewController()
            vc.delegate = self
            return vc
        }()
        
        init(setChannel: @escaping (GuideChannel) -> Void,
             setFocus: @escaping (FocusTarget) -> Void,
             toggleFavorite: @escaping (GuideChannel) -> Void,
             isSelectedChannel: @escaping (GuideChannel) -> Bool,
             isFavorite: @escaping (GuideChannel) -> Bool) {
            self.setChannel = setChannel
            self.setFocus = setFocus
            self.toggleFavorite = toggleFavorite
            self.isSelectedChannel = isSelectedChannel
            self.isFavorite = isFavorite
        }
    }
}

//MARK: - GuideViewControllerDelegate protocol

extension GuideViewRepresentable.Coordinator: @MainActor GuideViewControllerDelegate {
    func setFocused(target: FocusTarget) {
        self.setFocus(target)
    }
    
    func removeFocused(target: FocusTarget) {
        //Not yet implemented
    }
    
    func channelSelected(_ channel: GuideChannel) {
        setChannel(channel)
    }
    
    func favoriteToggled(_ channel: GuideChannel) {
        toggleFavorite(channel)
    }
    
    func isFavoriteChannel(_ channel: GuideChannel) -> Bool {
        return isFavorite(channel)
    }
    
    func isSelectedChannel(_ channel: GuideChannel) -> Bool {
        return isSelectedChannel(channel)
    }
}
