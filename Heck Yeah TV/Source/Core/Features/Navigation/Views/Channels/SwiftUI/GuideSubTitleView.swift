//
//  GuideSubTitleView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideSubTitleView: View {
    
    @State var channel: GuideChannel
    
    init(channel: GuideChannel) {
        self.channel = channel
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let n = channel.number {
                Text(n)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            if let quality = channel.quality.name {
                Text(quality)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 0)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke())
            }
            if channel.hasDRM {
                Text("DRM")
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 0)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke())
            }
        }
    }
}

#Preview() {
    let channel = GuideChannel(HDHomeRunChannel(guideNumber: "8.1",
                                       guideName: "WRIC-TV",
                                       videoCodec: "MPEG2",
                                       audioCodec: "AC3",
                                       hasDRM: true,
                                       isHD: true ,
                                       url: "http://192.168.50.250:5004/auto/v8.1"),
                               channelSource: .homeRunTuner)
    
    GuideSubTitleView(channel: channel)
        .background(Color.gray.opacity(0.5))
        .padding(.leading, 24)
}
