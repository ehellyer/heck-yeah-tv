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
    let content: () -> Content
    
    init(isReady: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._isReady = isReady
        self.content = content
    }
    
    var body: some View {
        ZStack {
           
            if !isReady {
                BootSplashView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                content()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isReady)
    }
}
