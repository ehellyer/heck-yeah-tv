//
//  SchemaCurrent.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

/// Denotes the schema version currently in effect.
typealias HeckYeahSchema = SchemaV3

/// Unique identifier of a channelId
typealias ChannelId = String

/// Unique identifier of a country
typealias CountryCode = String

/// Unique identifier of a TV stream category
typealias CategoryId = String

// Model typealias definitions - Models (always point to current schema in in use as defined by HeckYeahSchema typealias)
typealias HDHomeRunServer = HeckYeahSchema.HDHomeRunServer
typealias IPTVChannel = HeckYeahSchema.IPTVChannel
typealias IPTVCountry = HeckYeahSchema.IPTVCountry
typealias IPTVCategory = HeckYeahSchema.IPTVCategory
typealias StreamQuality = HeckYeahSchema.StreamQuality
typealias ChannelSource = HeckYeahSchema.ChannelSource
