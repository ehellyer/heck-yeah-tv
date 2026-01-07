//
//  NoChannelsFavorites.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/3/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NoChannelsFavorites: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tv.slash")
                .font(.system(size: 48))
                .foregroundStyle(.guideForegroundNoFocus)
            Text("No favorite channels set")
                .font(.headline)
                .foregroundStyle(.guideForegroundNoFocus)
            Text("Add some channels to your favorites")
                .font(.subheadline)
                .foregroundStyle(.guideForegroundNoFocus)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 60)
        .focusable(false)
        .background(Color.guideBackgroundNoFocus)
    }
}

#Preview {
    NoChannelsFavorites()
}
