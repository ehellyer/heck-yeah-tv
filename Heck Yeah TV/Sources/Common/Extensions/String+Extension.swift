//
//  String+Extension.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/16/20.
//  Copyright © 2020 Hellyer Multimedia. All rights reserved.
//

import Foundation

extension String {
        
    /// Generates a random string of length.
    /// - Parameter length: The length of string to be generated.
    /// - Returns: A new string of the specified length with random characters consisting of [a-z][A-Z][0-9]
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    /// Replaces a occurrences of a string with newString
    /// - Parameters:
    ///   - string: The search term to be replaced.
    ///   - newString: The replace term to replace the search term.
    mutating func replace(_ string: String, with newString: String) {
        self = self.replacingOccurrences(of: string, with: newString)
    }
    
    /// Trims white spaces and new line characters at the ends of the string.
    /// - Returns: Returns the cleansed string, which might be an empty string if all characters where whites spaces and/or new lines.
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /// Converts an empty string into a nil.
    /// - Returns: Returns nil if the string is empty, otherwise the original string is returned, but trimmed of whites spaces and / or new line characters.
    func nilIfEmpty() -> String? {
        let _self = self.trim()
        return _self.trim().isEmpty ? nil : _self
    }
    
    /// Concatenates the input string with self, while handling nil input strings and optionally including the separator.
    /// - Parameters:
    ///   - string: String to be concatenated onto self.
    ///   - separator: Optional separator string sequence.
    /// - Returns: Returns the resulting string with separator and input string.
    func concat(_ string: String?, separator: String? = "") -> String {
        let str2 = string ?? ""
        let sep = separator ?? ""
        return ((self.isEmpty) ? self : ((str2.isEmpty) ? self : self + sep)) + str2
    }
}
