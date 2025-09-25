//
//  PulseRings.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

//struct PulsingRings: View {
//    private let cycle: Double = 4.0         // seconds for one full loop
//    private let fadeDuration: Double = 0.1  // seconds for the fade-in
//    private let ringPeriod: Double = 1.6    // seconds for one ring to go 0→1
//    private let ringCount: Int = 4         // number of simultaneous rings
//
//    var body: some View {
//        TimelineView(.animation) { ctx in
//            let t = ctx.date.timeIntervalSinceReferenceDate
//            let base = t.truncatingRemainder(dividingBy: cycle) // 0..<cycle each loop
//
//            // Global fade-in at the start of each cycle (0 -> 1 over 0.1s)
//            let fade = min(1.0, max(0.0, base / fadeDuration))
//
//            Canvas { g, size in
//                let maxR = min(size.width, size.height) * 0.6
//
//                // Distribute ring phases evenly so some are always visible
//                for i in 0..<ringCount {
//                    let offset = Double(i) / Double(ringCount)  // 0, 1/N, 2/N, ...
//                    var phase = ((base / ringPeriod) + offset)
//                        .truncatingRemainder(dividingBy: 1.0)   // normalize to [0,1)
//                    if phase < 0 { phase += 1 }                 // keep positive
//
//                    let r = maxR * phase
//                    let alpha = max(0, 1 - phase)
//
//                    let rect = CGRect(
//                        x: size.width/2 - r,
//                        y: size.height/2 - r,
//                        width: r * 20,
//                        height: r * 4
//                    )
//
//                    let stroke = StrokeStyle(
//                        lineWidth: max(2, 6 * alpha),
//                        lineCap: .round
//                    )
//
//                    g.stroke(
//                        Path(ellipseIn: rect),
//                        with: .color(.white.opacity(0.28 * alpha /* * fade */)),
//                        style: stroke
//                    )
//                }
//            }
//            .opacity(fade) // global per-loop fade-in
//        }
//    }
//}


struct PulsingRings: View {
    
    var body: some View {
        TimelineView(.animation) { tlvContext in
            Canvas { gContext, size in
                let t = tlvContext.date.timeIntervalSinceReferenceDate
                let base = t.remainder(dividingBy: 4.0)
                let maxR = min(size.width, size.height) * 0.6
                for i in -8..<4 {
                    let phase = (base + Double(i).remainder(dividingBy: 1.6) / 1.6)
                    let r = maxR * phase
                    let alpha = (1 - phase)
                    
                    let rect = CGRect(x: (size.width * 0.6) - r,
                                      y: (size.height * 0.6) - r,
                                      width: r * 20,
                                      height: r * 4)
                    
                    let stroke = StrokeStyle(lineWidth: 6 * alpha,
                                             lineCap: .round)
                    
                    gContext.stroke(Path(ellipseIn: rect),
                                    with: .color(.white.opacity(0.28 * alpha)),
                                    style: stroke)
                }
                    
            }
            
        }
    }
}

#Preview() {
    PulsingRings()
        .ignoresSafeArea()
}
