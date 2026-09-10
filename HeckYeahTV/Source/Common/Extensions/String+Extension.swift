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

    /// Produces a stable, order-sensitive SHA-256 hash of two strings.
    ///
    /// Same two strings in the same order give the same hash every time, forever.
    /// Swap the order and you get an entirely different hash, because as far as
    /// this function is concerned `("A", "B")` and `("B", "A")` are not the same couple.
    ///
    /// The inputs are packed into a length-prefixed payload before hashing:
    /// ```
    /// [lenA][A bytes][lenB][B bytes]
    /// ```
    /// The length prefixes stop `"ab" + "c"` from colliding with `"a" + "bc"` —
    /// the kind of sneaky ambiguity that only ever surfaces in production.
    ///
    /// Example:
    /// ```swift
    /// String.stableHashHex("cat", "dog")   // "e4f7a31b4e1f…"
    /// String.stableHashHex("dog", "cat")   // "f2bc7a2dd041…" (a different beast entirely)
    /// ```
    ///
    /// - Parameters:
    ///   - a: The first string.
    ///   - b: The second string.
    /// - Returns: A 64-character hexadecimal SHA-256 digest.
    static func stableHashHex(_ a: String, _ b: String) -> String {
        let aData = Data(a.utf8)
        let bData = Data(b.utf8)

        // Build a length-prefixed payload: [lenA][a][lenB][b]
        var payload = Data()
        withUnsafeBytes(of: UInt32(aData.count).bigEndian) { payload.append(contentsOf: $0) }
        payload.append(aData)
        withUnsafeBytes(of: UInt32(bData.count).bigEndian) { payload.append(contentsOf: $0) }
        payload.append(bData)

        return SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
    }

    /// Generates a random alphanumeric string of the given length.
    ///
    /// Characters are drawn uniformly from `[a–z][A–Z][0–9]` — ideal for
    /// throwaway tokens, test fixtures, and placeholder names with a little
    /// more dignity than "Untitled 47".
    ///
    /// Example:
    /// ```swift
    /// String.randomString(length: 12)   // "aZ8nB31fQx2R"
    /// ```
    ///
    /// - Parameter length: How many characters to generate. Must be greater than zero.
    /// - Returns: A new random alphanumeric string.
    static func randomString(length: Int) -> String {
        precondition(length > 0, "Length must be greater than zero.")
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in letters.randomElement() })
    }

    /// Replaces every occurrence of one substring with another, in place.
    ///
    /// A mutating shorthand so you don't have to write `self = self.replacing…`
    /// and assign the receiver back to itself like it's 2014.
    ///
    /// Example:
    /// ```swift
    /// var phrase = "Hello, world!"
    /// phrase.replace("world", with: "Swift")   // "Hello, Swift!"
    /// ```
    ///
    /// - Parameters:
    ///   - string: The substring to hunt down.
    ///   - newString: What to leave in its place.
    mutating func replace(_ string: String, with newString: String) {
        self = self.replacingOccurrences(of: string, with: newString)
    }

    /// Returns a copy with leading and trailing whitespace and newlines removed.
    ///
    /// The tidy-up pass for strings that showed up with baggage. Interior spaces
    /// are left untouched — this trims the edges, not the middle.
    ///
    /// Example:
    /// ```swift
    /// "  Hello\n".trim()   // "Hello"
    /// ```
    ///
    /// - Returns: The trimmed string, which may be empty if there was nothing
    ///   but whitespace to begin with.
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns the trimmed string, or `nil` if trimming leaves nothing behind.
    ///
    /// Handy for optional-binding away strings that are technically present but
    /// spiritually empty — `"   "` is not a real value and we both know it.
    ///
    /// Example:
    /// ```swift
    /// "   ".nilIfEmpty()      // nil
    /// " hello ".nilIfEmpty()  // "hello"
    /// ```
    ///
    /// - Returns: The trimmed string, or `nil` if it is empty after trimming.
    func nilIfEmpty() -> String? {
        let trimmed = trim()
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Concatenates this string with another, quietly skipping the empties.
    ///
    /// Both sides are trimmed first. If one side is empty — `nil`, blank, or just
    /// a lonely space — you get the other side back with no dangling separator.
    /// No `"123 - "` awkwardness left hanging off the end.
    ///
    /// Example:
    /// ```swift
    /// " 123 ".concat("456", separator: " - ")   // "123 - 456"
    /// "123 ".concat(nil, separator: " - ")      // "123"
    /// "".concat("456", separator: " - ")        // "456"
    /// "123".concat("456")                       // "123456"
    /// ```
    ///
    /// - Parameters:
    ///   - string: The string to append. May be `nil` or empty.
    ///   - separator: Inserted only when both sides survive trimming. The
    ///     separator itself is not trimmed. Defaults to an empty string.
    /// - Returns: The combined string.
    func concat(_ string: String?, separator: String = "") -> String {
        [self, string ?? ""]
            .map { $0.trim() }
            .filter { !$0.isEmpty }
            .joined(separator: separator)
    }

    /// Concatenates two optional strings, quietly skipping the empties.
    ///
    /// The static sibling of ``concat(_:separator:)`` for when you have two
    /// optionals and no receiver to lean on. Same house rules: trim both, drop
    /// the blanks, and only reach for the separator when both sides actually
    /// show up. Chain ``nilIfEmpty()`` when "nothing at all" should become `nil`.
    ///
    /// Example:
    /// ```swift
    /// String.concat(nil, nil, separator: " - ")               // ""
    /// String.concat(nil, nil, separator: " - ").nilIfEmpty()  // nil
    /// String.concat(" 123 ", nil, separator: " - ")           // "123"
    /// String.concat(" 123 ", " 456", separator: " - ")        // "123 - 456"
    /// String.concat("123 ", " 456 ")                          // "123456"
    /// ```
    ///
    /// - Parameters:
    ///   - string1: The first string. `nil` counts as empty.
    ///   - string2: The second string. `nil` counts as empty.
    ///   - separator: Inserted only when both sides survive trimming. Defaults
    ///     to an empty string.
    /// - Returns: The combined string.
    static func concat(_ string1: String?, _ string2: String?, separator: String = "") -> String {
        (string1?.trim() ?? "").concat(string2, separator: separator)
    }
}
