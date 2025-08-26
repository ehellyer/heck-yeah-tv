//
//  String+Extension.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/25/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
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
    
    /// Conditionally concatenates self with the string parameter, separated by separator parameter.
    /// - Parameters:
    ///   - string: The string to be concatenated to self, separated by the string in the separator parameter.  This value can be nil or empty string.
    ///   - separator: The separator string that is used to concatenate self with the string parameter.  Default is empty string.
    ///
    /// Note: self and the string parameter are conditioned using the trim() function prior to checking and concatenation.
    ///
    /// Example of use:
    ///
    /// ````
    ///
    /// "123".concat("456", withSeparator: " - ")
    /// //returns "123 - 456"
    ///
    /// "123".concat(nil, withSeparator: " - ")
    /// //returns "123"
    ///
    /// "".concat("456", withSeparator: " - ")
    /// //returns "456"
    ///
    /// "123".concat("456")
    /// //returns "123456"
    ///
    /// ````
    ///
    /// - Returns: The completed string as a result of concatenation.
    func concat(_ string: String?, separator: String = "") -> String {
        let _self = self.trim()
        let str2 = string?.trim() ?? ""
        return ((_self.isEmpty) ? _self : ((str2.isEmpty) ? _self : _self + separator)) + str2
    }
    
    /// Conditionally concatenates string1 and string2, optionally separated by separator parameter.
    /// - Parameters:
    ///   - string1: The string in the first position.  When nil, it will be treated as an empty string.
    ///   - string2: The string in the second position.  When nil, it will be treated as an empty string.
    ///   - separator:  The separator string that is used to separate the concatenation of string1 and string2.  Default is empty string.
    ///
    /// __IMPORTANT__
    /// Note: string1 and string2 are trimmed of leading and trailing whitespace.
    ///
    /// Example of use:
    ///
    /// ````
    ///
    /// String.concat(nil, nil, separator: " - ")
    /// //returns ""
    ///
    /// String.concat(" 123 ", nil, separator: " - ")
    /// //returns "123"
    ///
    /// String.concat(nil, " 456 ", separator: " - ")
    /// //returns "456"
    ///
    /// String.concat(" 123 ", " 456", separator: " - ")
    /// //returns "123 - 456"
    ///
    /// String.concat(" 123 ", " ", separator: " - ")
    /// //returns "123"
    ///
    /// String.concat("123 ", " 456 ")
    /// //returns "123456"
    ///
    /// ````
    ///
    /// - Returns: The completed string as a result of concatenation.
    static func concat(_ string1: String?, _ string2: String?, separator: String = "") -> String {
        return (string1?.nilIfEmpty() ?? "").concat(string2, separator: separator)
    }
}
