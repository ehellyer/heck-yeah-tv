//
//  NoChannelsInChannelBundle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/3/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NoChannelsInChannelBundle: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tv.slash")
                .font(.system(size: 48))
                .foregroundStyle(.guideForegroundNoFocus)
            Text("There are no channels in this bundle")
                .font(.headline)
                .foregroundStyle(.guideForegroundNoFocus)
            Text("Goto settings to create your channel bundle")
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
    NoChannelsInChannelBundle()
}
