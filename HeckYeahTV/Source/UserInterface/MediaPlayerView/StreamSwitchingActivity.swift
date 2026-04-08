//
//  StreamSwitchingActivity.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/8/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct StreamSwitchingActivity: View {
    
    var body: some View {
        ZStack {
            Color.black
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                .controlSize(.large)
                .scaleEffect(2)
        }
    }
}

#Preview {
    StreamSwitchingActivity()
}

//struct FunActivity: View {
//
//    @State private var animationPhase: CGFloat = 0
//    @State private var scanlineProgress: CGFloat = 0
//
//    var body: some View {
//        ZStack {
//            Color.black
//
//            ZStack {
//                // Glow effect
//                TVShape()
//                    .fill(.white.opacity(0.3))
//                    .blur(radius: 20)
//                    .scaleEffect(1.2 + animationPhase * 0.2)
//
//                // Main TV shape
//                TVShape()
//                    .fill(.white.opacity(0.1))
//                    .shadow(color: .black.opacity(0.1), radius: 10)
//                    .scaleEffect(1.0 + animationPhase * 0.17)
//                    .overlay {
//                        // Screen area with scan lines
//                        GeometryReader { geometry in
//                            let screenRect = TVShape.screenRect(in: geometry.size)
//
//                            ZStack {
//                                // Screen background (draw first, behind everything)
//                                RoundedRectangle(cornerRadius: 8)
//                                    .fill(.white.opacity(0.15))
//                                    .frame(width: screenRect.width, height: screenRect.height)
//
//                                // Animated scan lines (draw on top)
//                                TimelineView(.animation) { timeline in
//                                    Canvas { context, size in
//                                        let lineHeight: CGFloat = 2
//                                        let lineSpacing: CGFloat = 6
//                                        let numberOfLines = Int(size.height / lineSpacing)
//
//                                        for lineIndex in 0..<numberOfLines {
//                                            let yOffset = CGFloat(lineIndex) * lineSpacing
//
//                                            // Calculate delay for cascading effect
//                                            let lineDelay = CGFloat(lineIndex) / CGFloat(max(numberOfLines - 1, 1))
//                                            let adjustedProgress = max(0, min(1, (scanlineProgress - lineDelay) / (1 - lineDelay * 0.7)))
//
//                                            if adjustedProgress > 0 {
//                                                // Line extends from left edge based on progress
//                                                let lineWidth = size.width * adjustedProgress
//
//                                                let linePath = Path { path in
//                                                    path.move(to: CGPoint(x: 0, y: yOffset))
//                                                    path.addLine(to: CGPoint(x: lineWidth, y: yOffset))
//                                                }
//
//
//                                                context.stroke(
//                                                    linePath,
//                                                    with: .color(.red),
//                                                    lineWidth: lineHeight
//                                                )
//                                            }
//                                        }
//                                    }
//                                    .frame(width: screenRect.width, height: screenRect.height)
//                                }
//                            }
//                            .position(x: screenRect.midX, y: screenRect.midY)
//                        }
//                    }
//                    .overlay {
//                        // TV outline
//                        TVShape()
//                            .stroke(.white, lineWidth: 3)
//                    }
//            }
//            .frame(width: 200, height: 160)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .onAppear {
//            startAnimations()
//        }
//    }
//
//    private func startAnimations() {
//        // Pulse animation for the TV
//        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
//            animationPhase = 1.0
//        }
//
//        // Scan line animation - use Timer for manual control
//        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
//            scanlineProgress += 0.01
//            if scanlineProgress >= 1.5 {
//                scanlineProgress = 0.0
//            }
//        }
//    }
//}
//
//// MARK: - Custom TV shape
//
//struct TVShape: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//
//        let width = rect.width
//        let height = rect.height
//
//        // Main TV body (rounded rectangle)
//        let bodyRect = CGRect(x: width * 0.1, y: height * 0.05, width: width * 0.8, height: height * 0.75)
//        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: 12, height: 12))
//
//        // Stand base
//        let standWidth = width * 0.4
//        let standHeight = height * 0.08
//        let standRect = CGRect(x: (width - standWidth) / 2, y: height * 0.85, width: standWidth, height: standHeight)
//        path.addRoundedRect(in: standRect, cornerSize: CGSize(width: 4, height: 4))
//
//        return path
//    }
//
//    static func screenRect(in size: CGSize) -> CGRect {
//        let width = size.width
//        let height = size.height
//
//        // Screen area inside the TV body with padding
//        let screenX = width * 0.15
//        let screenY = height * 0.12
//        let screenWidth = width * 0.7
//        let screenHeight = height * 0.6
//
//        return CGRect(x: screenX, y: screenY, width: screenWidth, height: screenHeight)
//    }
//}
