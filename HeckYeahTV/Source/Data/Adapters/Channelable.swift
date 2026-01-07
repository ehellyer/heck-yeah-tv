//
//  Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

protocol Channelable {
    
    /// The unique identifier of a channel in Heck Yeah TV.
    var idHint: ChannelId { get }
    
    /// The unique identifier to link guide information from the channels originating source.
    var guideIdHint: String? { get }
    
    /// A computed string used to sort the guide channel list.  This builds the order of the ChannelBundleMap.
    var sortHint: String { get }
    
    /// The title of the channel.
    var titleHint: String { get }
    
    /// The number of the channel (if appropriate)
    var numberHint: String? { get }
    
    /// The URL to the channel.
    var urlHint: URL { get }
    
    /// The advertised stream quality of the channel.  (The actual stream quality may differ)
    var qualityHint: StreamQuality { get }
    
    /// A Bool to indicate if the channel has a Digital Rights Management restriction.
    var hasDRMHint: Bool { get }
    
    /// Which system sourced this channel.  (e.g. "ipStream", "homeRunTuner")
    var sourceHint: ChannelSourceId { get }
    
    /// The device Id of the channel source.  (e.g. "20425D9B")
    var deviceIdHint: HDHomeRunDeviceId? { get }
    
    /// The URL to the channel logo image.
    var logoURLHint: URL? { get }
}
