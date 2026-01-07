//
//  DustyView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct DustyView: View {
    
    var body: some View {
        TimelineView(.animation) { tlvContext in
            Canvas { gContext, size in
                let t = tlvContext.date.timeIntervalSinceReferenceDate
                
                // Create large, slowly floating dust particles
                let particleCount = 60
                
                for i in 0..<particleCount {
                    // Use a deterministic but varied seed for each particle
                    let seed = Double(i) * 7.5432
                    
                    // Better random distribution using different trigonometric functions
                    let randomX = sin(seed * 3.14159) * cos(seed * 1.618)
                    let randomY = cos(seed * 2.71828) * sin(seed * 0.5772)
                    
                    let seedSin = sin(seed)
                    
                    // Very slow, gentle movement
                    let moveSpeed = 0.08 + abs(seedSin)
                    
                    // Starting position more randomly distributed across screen
                    let startX = (randomX * 0.5 + 0.5) * size.width
                    let startY = (randomY * 0.5 + 0.5) * size.height
                    
                    // Gentle floating motion in X and Y
                    let driftX = sin(t * moveSpeed + seed) * 50.0
                    let driftY = cos(t * moveSpeed * 0.7 + seed * 1.4) * 40.0
                    
                    let x = startX + driftX
                    let y = startY + driftY
                    
                    // Large particle sizes
                    let baseSize = 40.0 + (abs(randomX) * 60.0) // 40-100 pixels
                    let breathPhase = sin(t * 0.3 + seed) * 0.2 + 0.8 // Gentle breathing
                    let particleSize = baseSize * breathPhase
                    
                    // Soft, gentle opacity
                    let brightness = 0.7
                    let baseOpacity = 0.08 + (abs(randomY) * 0.08)
                    let opacityPulse = (sin(t * 0.25 + seed * 0.5) * 0.3) + brightness
                    let opacity = baseOpacity * opacityPulse
                    
                    // Draw the main particle with soft edges
                    let particleRect = CGRect(x: x - particleSize / 2,
                                              y: y - particleSize / 2,
                                              width: particleSize,
                                              height: particleSize)
                    
                    gContext.fill(Path(ellipseIn: particleRect),
                                  with: .color(.white.opacity(opacity)))
                    
                    // Add multiple glow layers for softer appearance
                    for glowLayer in 1...2 {
                        let glowMultiplier = 1.0 + (Double(glowLayer) * 0.4)
                        let glowSize = particleSize * glowMultiplier
                        let glowOpacity = opacity / Double(glowLayer + 1)
                        
                        let glowRect = CGRect(x: x - glowSize / 2,
                                              y: y - glowSize / 2,
                                              width: glowSize,
                                              height: glowSize)
                        
                        gContext.fill(Path(ellipseIn: glowRect),
                                      with: .color(.white.opacity(glowOpacity * 0.3)))
                    }
                }
            }
        }
    }
}

#Preview("Original") {
    DustyView()
        .ignoresSafeArea()
        .background(Color.black)
}
