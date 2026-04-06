//
//  UnplayableStreamOverlay.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/6/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct UnplayableStreamOverlay: View {
    var body: some View {
        Image(systemName: "play.slash")
            .font(.system(size: 100))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.white.opacity(0.7))
            .shadow(color: .black.opacity(0.5), radius: 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
    }
}
