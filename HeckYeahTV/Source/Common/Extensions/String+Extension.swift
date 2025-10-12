//
//  String+Extension.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/25/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import CryptoKit

extension String {

    /// Computes a **stable, order-sensitive SHA-256 hash** of two input strings.
    ///
    /// The resulting hash is deterministic and will always produce the same
    /// output for the same ordered pair of input strings.
    /// Note that the operation is **order-sensitive** — meaning:
    /// ```swift
    /// stableHashHex("A", "B") != stableHashHex("B", "A")
    /// ```
    ///
    /// Internally, the function builds a length-prefixed payload in the form:
    /// ```
    /// [lenA][A bytes][lenB][B bytes]
    /// ```
    /// to ensure that inputs are unambiguously encoded and collisions are minimized.
    ///
    /// Example:
    /// ```swift
    /// let hash1 = String.stableHashHex("cat", "dog")
    /// let hash2 = String.stableHashHex("dog", "cat")
    ///
    /// print(hash1)
    /// // "e4f7a31b4e1f... (unique hex value)"
    ///
    /// print(hash2)
    /// // "f2bc7a2dd041... (different hex value)"
    /// ```
    ///
    /// - Parameters:
    ///   - a: The first input string.
    ///   - b: The second input string.
    /// - Returns: A 64-character hexadecimal string representing the SHA-256 digest
    ///   of the combined inputs.
    static func stableHashHex(_ a: String, _ b: String) -> String {
        let aData = Data(a.utf8)
        let bData = Data(b.utf8)
        
        // Build length-prefixed payload: [lenA][a][lenB][b]
        var payload = Data()
        var lenA = UInt32(aData.count).bigEndian
        var lenB = UInt32(bData.count).bigEndian
        withUnsafeBytes(of: &lenA) { payload.append(contentsOf: $0) }
        payload.append(aData)
        withUnsafeBytes(of: &lenB) { payload.append(contentsOf: $0) }
        payload.append(bData)
        
        let digest = SHA256.hash(data: payload)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Generates a random alphanumeric string of the specified length.
    ///
    /// Characters are chosen uniformly at random from the set:
    /// `[a–z][A–Z][0–9]`.
    ///
    /// Example:
    /// ```swift
    /// let token = String.randomString(length: 12)
    /// print(token)
    /// // "aZ8nB31fQx2R"
    /// ```
    ///
    /// - Parameter length: The number of characters to generate.
    /// - Returns: A new string containing random alphanumeric characters.
    static func randomString(length: Int) -> String {
        precondition(length > 0, "Length must be greater than zero.")
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in letters.randomElement() })
    }
    
    /// Replaces all occurrences of a substring with another string.
    ///
    /// This is a mutating convenience method equivalent to:
    /// ```swift
    /// self = self.replacingOccurrences(of: oldValue, with: newValue)
    /// ```
    ///
    /// Example:
    /// ```swift
    /// var phrase = "Hello, world!"
    /// phrase.replace("world", with: "Swift")
    /// print(phrase)
    /// // "Hello, Swift!"
    /// ```
    ///
    /// - Parameters:
    ///   - string: The substring to search for.
    ///   - newString: The replacement string to substitute for all matches.
    mutating func replace(_ string: String, with newString: String) {
        self = self.replacingOccurrences(of: string, with: newString)
    }
    
    /// Returns a copy of the string with leading and trailing whitespace
    /// and newline characters removed.
    ///
    /// Example:
    /// ```swift
    /// "  Hello\n".trim()
    /// // returns "Hello"
    /// ```
    ///
    /// - Returns: A new string trimmed of whitespace and newline characters.
    ///   The result may be an empty string if the receiver contained only
    ///   whitespace or newline characters.
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /// Returns `nil` if the string is empty after trimming whitespace
    /// and newline characters; otherwise returns the trimmed string.
    ///
    /// Example:
    /// ```swift
    /// "  ".nilIfEmpty()
    /// // returns nil
    ///
    /// " hello ".nilIfEmpty()
    /// // returns "hello"
    /// ```
    ///
    /// - Returns: The trimmed string, or `nil` if it is empty after trimming.
    func nilIfEmpty() -> String? {
        let trimmed = self.trim()
        return trimmed.isEmpty ? nil : trimmed
    }
    
    /// Concatenates the current string with another string, optionally separated
    /// by a given separator, while ignoring empty or whitespace-only strings.
    ///
    /// Both the receiver and the supplied string are trimmed of whitespace
    /// and newline characters before concatenation. If either value is empty,
    /// the non-empty value is returned without applying the separator.
    ///
    /// Example:
    /// ```swift
    /// " 123 ".concat("456", separator: " - ")
    /// // returns "123 - 456"
    ///
    /// "123 ".concat(nil, separator: " - ")
    /// // returns "123"
    ///
    /// "".concat("456", separator: " - ")
    /// // returns "456"
    ///
    /// "123".concat("456")
    /// // returns "123456"
    /// ```
    ///
    /// - Parameters:
    ///   - string: The string to append. May be `nil` or empty.
    ///   - separator: A string to insert between values when both are non-empty.
    ///     The separator is not trimmed.
    ///     The default is an empty string.
    /// - Returns: A concatenated string result.
    func concat(_ string: String?, separator: String = "") -> String {
        let trimmedSelf = self.trim()
        let trimmedString = string?.trim() ?? ""
        if trimmedSelf.isEmpty { return trimmedString }
        if trimmedString.isEmpty { return trimmedSelf }
        return trimmedSelf + separator + trimmedString
    }
    
    /// Concatenates two strings, optionally separated by a given separator,
    /// while ignoring `nil` or whitespace-only values.
    ///
    /// Each input string is trimmed before concatenation. If either value
    /// becomes empty, the non-empty value is returned without applying the separator.
    ///
    /// Example:
    /// ```swift
    /// String.concat(nil, nil, separator: " - ")
    /// // returns ""
    ///
    /// String.concat(nil, nil, separator: " - ").nilIfEmpty()
    /// // returns nil
    ///
    /// String.concat(" 123 ", nil, separator: " - ")
    /// // returns "123"
    ///
    /// String.concat(nil, " 456 ", separator: " - ")
    /// // returns "456"
    ///
    /// String.concat(" 123 ", " 456", separator: " - ")
    /// // returns "123 - 456"
    ///
    /// String.concat(" 123 ", " ", separator: " - ")
    /// // returns "123"
    ///
    /// String.concat("123 ", " 456 ")
    /// // returns "123456"
    /// ```
    ///
    /// - Parameters:
    ///   - string1: The first string. `nil` is treated as an empty string.
    ///   - string2: The second string. `nil` is treated as an empty string.
    ///   - separator: A string to insert between values when both are non-empty.
    ///     The default is an empty string.
    /// - Returns: A concatenated string result.
    static func concat(_ string1: String?, _ string2: String?, separator: String = "") -> String {
        return (string1?.trim() ?? "").concat(string2, separator: separator)
    }
}
