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
        HStack(spacing: 15) {
            if let n = channel.number {
                Text(n).font(.caption).foregroundStyle(.secondary)
            }
            if channel.quality.name != nil {
                Text(channel.quality.name!)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke())
            }
            if channel.hasDRM {
                Text("DRM")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke())
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
}
