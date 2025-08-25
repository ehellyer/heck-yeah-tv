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
    
    /// Creates the custom instance that you use to communicate changes from
    /// your view to other parts of your SwiftUI interface.
    ///
    /// Implement this method if changes to your view might affect other parts
    /// of your app. In your implementation, create a custom Swift instance that
    /// can communicate with other parts of your interface. For example, you
    /// might provide an instance that binds its variables to SwiftUI
    /// properties, causing the two to remain synchronized. If your view doesn't
    /// interact with other parts of your app, providing a coordinator is
    /// unnecessary.
    ///
    /// SwiftUI calls this method before calling the
    /// ``UIViewRepresentable/makeUIView(context:)`` method. The system provides
    /// your coordinator either directly or as part of a context structure when
    /// calling the other methods of your representable instance.
    func makeCoordinator() -> VLCPlayerWrapperView.Coordinator {
        return VLCPlayerWrapperView.Coordinator()
    }
    
    /// Creates the view object and configures its initial state.
    ///
    /// You must implement this method and use it to create your view object.
    /// Configure the view using your app's current data and contents of the
    /// `context` parameter. The system calls this method only once, when it
    /// creates your view for the first time. For all subsequent updates, the
    /// system calls the ``UIViewRepresentable/updateUIView(_:context:)``
    /// method.
    ///
    /// - Parameter context: A context structure containing information about
    ///   the current state of the system.
    ///
    /// - Returns: Your UIKit view configured with the provided information.
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        context.coordinator.attach(to: view)
        return view
    }
    
    /// Updates the state of the specified view with new information from
    /// SwiftUI.
    ///
    /// When the state of your app changes, SwiftUI updates the portions of your
    /// interface affected by those changes. SwiftUI calls this method for any
    /// changes affecting the corresponding UIKit view. Use this method to
    /// update the configuration of your view to match the new state information
    /// provided in the `context` parameter.
    ///
    /// - Parameters:
    ///   - uiView: Your custom view object.
    ///   - context: A context structure containing information about the current
    ///     state of the system.
    func updateUIView(_ uiView: UIView, context: Context) {

    }
    
    /// Cleans up the presented UIKit view (and coordinator) in anticipation of
    /// their removal.
    ///
    /// Use this method to perform additional clean-up work related to your
    /// custom view. For example, you might use this method to remove observers
    /// or update other parts of your SwiftUI interface.
    ///
    /// - Parameters:
    ///   - uiView: Your custom view object.
    ///   - coordinator: The custom coordinator instance you use to communicate
    ///     changes back to SwiftUI. If you do not use a custom coordinator, the
    ///     system provides a default instance.
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
    final class Coordinator: NSObject {
        private lazy var mediaPlayer = VLCMediaPlayer()
        
        func attach(to view: UIView) {
            mediaPlayer.drawable = view
        }
        
        func play(channel: Channelable) {
            mediaPlayer.media = VLCMedia(url: channel.urlHint)
            mediaPlayer.play()
        }
        
        func seekForward() {
            guard self.mediaPlayer.isSeekable else { return }
            self.mediaPlayer.position = min(1.0, self.mediaPlayer.position * 1.01)
        }
        
        func seekBackward() {
            guard self.mediaPlayer.isSeekable else { return }
            self.mediaPlayer.position = max(0.0, self.mediaPlayer.position * -1.01)
        }
        
        func pause() {
            guard self.mediaPlayer.canPause else { return }
            self.mediaPlayer.pause()
        }
        
        func stop() {
            guard self.mediaPlayer.isPlaying else { return }
            self.mediaPlayer.stop()
        }
        
        func dismantle() {
            mediaPlayer.drawable = nil
        }
    }
}
