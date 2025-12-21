//
//  SchemaCurrent.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

/// Denotes the schema version currently in effect.
typealias HeckYeahSchema = SchemaV1

/// Type used as the unique identifier of a Guide.
typealias GuideId = String

/// Type used as the unique identifier of a IPTVChannel.  The id is a stable hash of URL and one other non-optional property of `IPStream` or `HDHomeRunChannel`.
typealias ChannelId = String

/// Type used as the unique identifier of a country
typealias CountryCode = String

/// Type used as the unique identifier of a TV stream category
typealias CategoryId = String

/// Type used as the unique identifier of a language.
typealias LanguageCode = String

/// Type used as the source of the channel
typealias ChannelSource = String

// Model typealias definitions - Models (always point to current schema in use as defined by HeckYeahSchema typealias)
typealias Guide = HeckYeahSchema.Guide
typealias HDHomeRunServer = HeckYeahSchema.HDHomeRunServer
typealias IPTVCategory = HeckYeahSchema.IPTVCategory
typealias IPTVChannel = HeckYeahSchema.IPTVChannel
typealias IPTVCountry = HeckYeahSchema.IPTVCountry
typealias IPTVFavorite = HeckYeahSchema.IPTVFavorite
typealias SchemaVersion = HeckYeahSchema.SchemaVersion
typealias StreamQuality = HeckYeahSchema.StreamQuality
