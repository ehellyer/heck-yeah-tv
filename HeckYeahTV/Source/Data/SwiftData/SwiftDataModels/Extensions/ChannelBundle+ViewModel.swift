//
//  ChannelBundle+ViewModel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/22/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

extension ChannelBundle {
    
    /// Returns the active channel count in the channel bundle by filtering our channels that are nil.
    /// Note: BundleEntries are kept around after their associated channel is deleted as they hold information such as isFavorite.
    /// If the channel returns to the catalog, the existing bundleEntry will be re-associated to that channel.
    /// This happens much more on iPhone and iPad with HDHomeRunDevices where the user will frequently not be on their
    /// home network where the device is unreachable.
    var bundleChannelCount: Int {
        return self.channelEntries.filter({ $0.channel != nil }).count
    }
}
