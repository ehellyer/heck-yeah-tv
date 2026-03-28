//
//  XMLTVGuide.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 3/26/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Represents the root XMLTV guide document
struct XMLTVGuide: Codable {
    let channels: [XMLTVChannel]
    let programs: [XMLTVProgram]
    
    enum CodingKeys: String, CodingKey {
        case channels = "channel"
        case programs = "program"
    }
}

/// Represents a TV channel in XMLTV format
struct XMLTVChannel: Codable, Identifiable {
    let id: String
    let displayNames: [XMLTVDisplayName]
    let icons: [XMLTVIcon]?
    let urls: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayNames = "display-name"
        case icons = "icon"
        case urls = "url"
    }
}

/// Represents a display name for a channel
struct XMLTVDisplayName: Codable {
    let value: String
    let lang: String?
    
    enum CodingKeys: String, CodingKey {
        case value = ""
        case lang
    }
}

/// Represents a channel icon/logo
struct XMLTVIcon: Codable {
    let src: String
    let width: Int?
    let height: Int?
}

/// Represents a TV program/show in XMLTV format
struct XMLTVProgram: Codable, Identifiable {
    let channel: String
    let start: String
    let stop: String
    let titles: [XMLTVTitle]
    let subTitles: [XMLTVTitle]?
    let descriptions: [XMLTVDescription]?
    let categories: [XMLTVCategory]?
    let icons: [XMLTVIcon]?
    let episodeNum: [XMLTVEpisodeNum]?
    let date: String?
    let credits: XMLTVCredits?
    let rating: [XMLTVRating]?
    let starRating: [XMLTVStarRating]?
    let previouslyShown: XMLTVPreviouslyShown?
    let premiere: XMLTVPremiere?
    let new: XMLTVNew?
    
    var id: String {
        "\(channel)-\(start)"
    }
    
    enum CodingKeys: String, CodingKey {
        case channel
        case start
        case stop
        case titles = "title"
        case subTitles = "sub-title"
        case descriptions = "desc"
        case categories = "category"
        case icons = "icon"
        case episodeNum = "episode-num"
        case date
        case credits
        case rating
        case starRating = "star-rating"
        case previouslyShown = "previously-shown"
        case premiere
        case new
    }
}

/// Represents a program title
struct XMLTVTitle: Codable {
    let value: String
    let lang: String?
    
    enum CodingKeys: String, CodingKey {
        case value = ""
        case lang
    }
}

/// Represents a program description
struct XMLTVDescription: Codable {
    let value: String
    let lang: String?
    
    enum CodingKeys: String, CodingKey {
        case value = ""
        case lang
    }
}

/// Represents a program category
struct XMLTVCategory: Codable {
    let value: String
    let lang: String?
    
    enum CodingKeys: String, CodingKey {
        case value = ""
        case lang
    }
}

/// Represents episode numbering information
struct XMLTVEpisodeNum: Codable {
    let value: String
    let system: String?
    
    enum CodingKeys: String, CodingKey {
        case value = ""
        case system
    }
}

/// Represents credits (actors, directors, etc.)
struct XMLTVCredits: Codable {
    let directors: [String]?
    let actors: [XMLTVActor]?
    let writers: [String]?
    let adapters: [String]?
    let producers: [String]?
    let composers: [String]?
    let editors: [String]?
    let presenters: [String]?
    let commentators: [String]?
    let guests: [String]?
    
    enum CodingKeys: String, CodingKey {
        case directors = "director"
        case actors = "actor"
        case writers = "writer"
        case adapters = "adapter"
        case producers = "producer"
        case composers = "composer"
        case editors = "editor"
        case presenters = "presenter"
        case commentators = "commentator"
        case guests = "guest"
    }
}

/// Represents an actor with optional role
struct XMLTVActor: Codable {
    let name: String
    let role: String?
    
    enum CodingKeys: String, CodingKey {
        case name = ""
        case role
    }
}

/// Represents a content rating
struct XMLTVRating: Codable {
    let system: String?
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case system
        case value
    }
}

/// Represents a star rating
struct XMLTVStarRating: Codable {
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case value
    }
}

/// Indicates a previously shown program
struct XMLTVPreviouslyShown: Codable {
    let start: String?
    let channel: String?
}

/// Indicates a premiere
struct XMLTVPremiere: Codable {
    let value: String?
    let lang: String?
    
    enum CodingKeys: String, CodingKey {
        case value = ""
        case lang
    }
}

/// Indicates a new program
struct XMLTVNew: Codable {
    // Empty struct just to mark presence
}
