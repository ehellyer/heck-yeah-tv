//
//  IPTVCountry.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class IPTVCountry: JSONSerializable {
        #Index<IPTVCountry>([\.code])
        
        init(name: String,
             code: CountryCode,
             languages: [String],
             flag: String) {
            self.name = name
            self.code = code
            self.languages = languages
            self.flag = flag
        }
        
        /// Name of the country
        var name: String
        
        /// [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code of the country
        @Attribute(.unique)
        var code: CountryCode
        
        /// List of official languages of the country ([ISO 639-3](https://en.wikipedia.org/wiki/ISO_639-3) code)
        var languages: [String]
        
        /// Country flag emoji
        var flag: String
        
        // MARK: - JSONSerializable Implementation
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case name
            case code
            case languages
            case flag
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(code, forKey: .code)
            try container.encode(languages, forKey: .languages)
            try container.encode(flag, forKey: .flag)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.code = try container.decode(CountryCode.self, forKey: .code)
            self.languages = try container.decode([String].self, forKey: .languages)
            self.flag = try container.decode(String.self, forKey: .flag)
        }
    }
}
