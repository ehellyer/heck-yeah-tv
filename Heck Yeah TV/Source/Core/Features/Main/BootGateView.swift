//
//  BootGateView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/25/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct BootGateView<Content: View>: View {
    @Binding var isReady: Bool
    @State var minimumDelayElapsed: Bool = false
    let content: () -> Content
    
    init(isReady: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        _isReady = isReady
        self.content = content
    }
    
    var body: some View {
        ZStack {
           
            if isReady && minimumDelayElapsed {
                content()
            } else {
                BootSplashView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: (isReady && minimumDelayElapsed))
        .onAppear() {
            let delayInSeconds: Double = 4.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                minimumDelayElapsed = true
            }
        }
    }
}
