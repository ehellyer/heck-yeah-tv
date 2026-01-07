//
//  SchemaCurrent.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

// Denotes the schema version currently in effect for this app.  (Used by `UpgradeSchemaMigrationPlan.swift`)
typealias HeckYeahSchema = SchemaV1

// Model typealias definitions - Models (always point to current schema in use as defined by HeckYeahSchema typealias)
typealias ChannelBundle = HeckYeahSchema.ChannelBundle
typealias ChannelProgram = HeckYeahSchema.ChannelProgram
typealias HomeRunDevice = HeckYeahSchema.HomeRunDevice
typealias ProgramCategory = HeckYeahSchema.ProgramCategory
typealias Channel = HeckYeahSchema.Channel
typealias Country = HeckYeahSchema.Country
typealias Favorite = HeckYeahSchema.Favorite
typealias SchemaVersion = HeckYeahSchema.SchemaVersion
typealias StreamQuality = HeckYeahSchema.StreamQuality

//MARK: - Identifier type aliases

/// Type used as the unique identifier of a ChannelBundle.
typealias ChannelBundleId = String

/// Type used as the unique identifier of a Channel.  The id is a stable hash of URL and one other non-optional property of `IPStream` or `HDHomeRunChannel`.
typealias ChannelId = String

/// Type used as the unique identifier of a channel program instance.
typealias ChannelProgramId = String

/// Type used as the unique identifier of a country
typealias CountryCodeId = String

/// Type used as the unique identifier of a TV stream category
typealias CategoryId = String

/// Type used as the unique identifier of a language.
typealias LanguageCodeId = String

/// Type used as the unique identifier of the channel source.  (See enum `ChannelSourceType` for definitions)
typealias ChannelSourceId = String

/// Type used to hold an instance of a channels guide number. (e.g. HDHR: "12.1" or IPTV: "France3.fr")
typealias GuideNumber = String
