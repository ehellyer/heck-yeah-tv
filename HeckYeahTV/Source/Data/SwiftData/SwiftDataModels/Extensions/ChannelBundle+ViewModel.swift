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
    
    /// Checks if a `HomeRunDevice` is associated with a this `ChannelBundle`. Like checking your party guest list.
    ///
    /// This function peeks into the `ChannelBundleDevice` join table to see if the device
    /// is already linked to the bundle. Returns true if they're BFFs, false if they've never met.
    ///
    /// - Parameters:
    ///   - device: The HDHomeRun device you're curious about.
    ///
    /// - Returns: True if the device is associated with the bundle, false otherwise.
    func isAssociated(with device: HomeRunDevice) -> Bool {
        return self.deviceAssociations.contains(where: { $0.device.deviceId == device.deviceId })
    }
}
