//
//  VLCPlayerWrapperView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/19/25.
//

import SwiftUI
#if os(tvOS)
import TVVLCKit
#else
import MobileVLCKit
#endif

struct VLCPlayerWrapperView: UIViewRepresentable {
    
    let url: URL
    var autoplay: Bool = true
    var isMuted: Bool = false
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        context.coordinator.attach(to: view, muted: isMuted)
        
        if autoplay {
            context.coordinator.play(url: url)
        } else {
            context.coordinator.setMedia(url: url)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.setMuted(isMuted)
        context.coordinator.updateIfNeeded(url: url,
                                           autoplay: autoplay)
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stop()
    }
    
    final class Coordinator: NSObject {
        private let player = VLCMediaPlayer()
        private var currentURL: URL?
        
        func attach(to view: UIView, muted: Bool) {
            player.drawable = view
#if os(tvOS) || os(iOS)
            player.audio?.isMuted = muted
#endif
        }
        
        func setMuted(_ muted: Bool) {
#if os(tvOS) || os(iOS)
            player.audio?.isMuted = muted
#endif
        }
        
        func setMedia(url: URL) {
            currentURL = url
            player.media = VLCMedia(url: url)
        }
        
        func play(url: URL) {
            setMedia(url: url)
            player.play()
        }
        
        func updateIfNeeded(url: URL, autoplay: Bool) {
            guard url != currentURL else {
                return
            }
            if autoplay {
                play(url: url)
            } else {
                setMedia(url: url)
            }
        }
        
        func stop() {
            player.stop()
            player.drawable = nil
        }
    }
}
