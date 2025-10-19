// PlaylistResolver.swift
// HeckYeahTV

import Foundation

enum PlaylistResolverError: Error {
    case invalidResponse
    case notFound
}

struct PlaylistResolver {
    
    static func resolve(url: URL) async throws -> URL {
        // If it looks like HLS, return as-is.
        if url.pathExtension.lowercased() == "m3u8" {
            return url
        }
        // If not .m3u, assume it’s a direct media URL; return as-is.
        if url.pathExtension.lowercased() != "m3u" {
            return url
        }
        
        // Fetch the playlist text
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let text = String(data: data, encoding: .utf8) else {
            throw PlaylistResolverError.invalidResponse
        }
        
        // Basic EXTM3U parsing: collect candidate URLs
        // Prefer .m3u8, else any absolute URL, else resolve relative.
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        
        // Try to find .m3u8 first
        if let hlsLine = lines.first(where: { $0.lowercased().contains(".m3u8") }) {
            if let abs = URL(string: hlsLine), abs.scheme != nil {
                return abs
            } else if let resolved = URL(string: hlsLine, relativeTo: url)?.absoluteURL {
                return resolved
            }
        }
        
        // Else first usable URL
        if let firstLine = lines.first {
            if let abs = URL(string: firstLine), abs.scheme != nil {
                return abs
            } else if let resolved = URL(string: firstLine, relativeTo: url)?.absoluteURL {
                return resolved
            }
        }
        
        throw PlaylistResolverError.notFound
    }
}
