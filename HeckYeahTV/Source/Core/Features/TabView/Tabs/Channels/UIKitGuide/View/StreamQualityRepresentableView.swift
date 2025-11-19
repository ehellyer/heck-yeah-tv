//
//  StreamQualityRepresentableView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI
import SwiftData

struct StreamQualityRepresentableView: CrossPlatformRepresentable {

    let streamQuality: StreamQuality?
    
    //MARK: - CrossPlatformRepresentable overrides

    func makeCoordinator() -> StreamQualityRepresentableView.Coordinator {
        return Coordinator(streamQuality: streamQuality)
    }
    
    func makeView(context: Context) -> PlatformView {
        return context.coordinator.platformView
    }
    
    func updateView(_ view: PlatformView, context: Context) {

    }
    
    static func dismantleView(_ view: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
    //MARK: - ViewRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject {

        init(streamQuality: StreamQuality?) {
            self.platformView = StreamQualityView(streamQuality: streamQuality ?? .unknown)
        }
       
        //MARK: - Internal API
        
        let platformView: PlatformView
        
        func dismantle() {
            platformView.removeFromSuperview()
        }
    }
}
