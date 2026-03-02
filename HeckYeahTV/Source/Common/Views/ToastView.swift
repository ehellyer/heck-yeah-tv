//
//  ToastView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/1/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

// MARK: - Toast Message Model

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.text == rhs.text
    }
}

// MARK: - Toast Manager

@MainActor
@Observable
final class ToastManager {
    static let shared = ToastManager()
    
    private init() {}
    
    private(set) var currentToast: ToastMessage?
    private var displayTask: Task<Void, Never>?
    
    /// Shows a toast message immediately. If the same message is already displayed,
    /// the timer is NOT reset. If a different message is displayed, it replaces the
    /// current one and resets the timer.
    func show(_ message: String) {
        // If the current toast has the same message, do nothing (don't reset timer)
        if let current = currentToast, current.text == message {
            return
        }
        
        // New message - display it immediately
        let newToast = ToastMessage(text: message)
        currentToast = newToast
        
        // Cancel previous timer and start a new one
        displayTask?.cancel()
        displayTask = Task { @MainActor in
            // Display for 3 seconds
            try? await Task.sleep(for: .seconds(3))
            
            // Check if task wasn't cancelled
            guard !Task.isCancelled else { return }
            
            // Fade out the toast
            currentToast = nil
        }
    }
    
    /// Hides the current toast immediately
    func clear() {
        displayTask?.cancel()
        currentToast = nil
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.body)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect()
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Toast Container View Modifier

struct ToastContainerModifier: ViewModifier {
    @State private var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Toast overlay
            VStack {
                Spacer()
                
                if let toast = toastManager.currentToast {
                    ToastView(message: toast.text)
                        .id(toast.text) // Force view recreation when text changes
                        .padding(.bottom, 100)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: toastManager.currentToast?.text)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds toast notification support to any view
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}

// MARK: - Preview

#Preview("Toast Messages") {
    @Previewable @State var showToast = false
    
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 20) {
            Button("Message 1") {
                ToastManager.shared.show("This is a message")
            }
            .buttonStyle(.borderedProminent)
            
            Button("Message 2") {
                ToastManager.shared.show("This is another message.")
            }
            .buttonStyle(.borderedProminent)
            
            Button("Multi-message same message (Won't change for same string)") {
                ToastManager.shared.show("Same message")
                ToastManager.shared.show("Same message")
                ToastManager.shared.show("Same message")
            }
            .buttonStyle(.borderedProminent)

            
            Button("Multi-message unique message (Last one in wins)") {
                ToastManager.shared.show("Message 1")
                ToastManager.shared.show("Message 2")
                ToastManager.shared.show("Message 3")
            }
            .buttonStyle(.borderedProminent)

            
            Button("Dismiss early") {
                ToastManager.shared.clear()
            }
            .buttonStyle(.bordered)
        }
    }
    .toastContainer()
}
