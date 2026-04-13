//
//  EPGController.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 3/26/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

enum EPGControllerError: LocalizedError {
    case invalidURL
    case downloadFailed(Error)
    case decompressFailed
    case parseFailed(Error)
    
    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "The EPG URL is invalid."
            case .downloadFailed(let error):
                return "Failed to download EPG data: \(error.localizedDescription)"
            case .decompressFailed:
                return "Failed to decompress EPG data."
            case .parseFailed(let error):
                return "Failed to parse EPG XML data: \(error.localizedDescription)"
        }
    }
}

actor EPGController {
    
    deinit {
        logDebug("Deallocated")
    }
    
    // MARK: - Private API
    
    private let sessionInterface: SessionInterface = SessionInterface.sharedInstance
    
    private var defaultHeaders: [HTTPHeader] = [
        HTTPHeader.defaultUserAgent,
        HTTPHeader(name: "Accept-Encoding", value: "gzip, deflate"),
        HTTPHeader(name: "Accept", value: "application/xml, text/xml")
    ]
    
    /// Downloads EPG data from the specified URL
    /// - Parameters:
    ///   - urlString: The URL string for the EPG source
    /// - Returns: The raw XML data
    private func downloadEPG(from url: URL) async throws -> Data {
        let request = NetworkRequest(url: url,
                                     method: .get,
                                     timeoutInterval: 60.0,
                                     headers: self.defaultHeaders)
        
        do {
            let response = try await sessionInterface.execute(request)
            guard let data = response.body else {
                throw EPGControllerError.decompressFailed
            }
            return data
        } catch {
            throw EPGControllerError.downloadFailed(error)
        }
    }
    
    /// Parses XMLTV data into structured format
    /// - Parameter xmlData: The raw XML data
    /// - Returns: Parsed XMLTVGuide structure
    private func parseXMLTV(_ xmlData: Data) async throws -> XMLTVGuide {
        let parser = XMLTVParser()
        
        do {
            let guide = try parser.parse(xmlData)
            return guide
        } catch {
            throw EPGControllerError.parseFailed(error)
        }
    }
    
    // MARK: - Internal API
    
    /// Fetches and parses EPG data from the specified source
    /// - Parameters:
    ///   - source: The EPG source URL string
    ///   - compressed: Whether the source file is gzip compressed (default: true)
    /// - Returns: FetchSummary with success/failure information
    func fetchEPG(from source: String) async -> (guide: XMLTVGuide?, summary: FetchSummary) {
        var summary = FetchSummary()
        
        guard let sourceURL = URL(string: source) else {
            summary.addFailure(forKey: .iptvGuides, value: EPGControllerError.invalidURL.errorDescription ?? "")
            summary.finishedAt = Date()
            return (nil, summary)
        }
        
        do {
            logDebug("Downloading EPG data from: \(sourceURL)")
            let xmlData = try await downloadEPG(from: sourceURL)
            
            logDebug("Parsing EPG XML data (\(xmlData.count) bytes)...")
            let guide = try await parseXMLTV(xmlData)
            
            logDebug("Successfully parsed EPG: \(guide.channels.count) channels, \(guide.programs.count) programs")
            summary.addSuccess(forKey: .iptvGuides, value: "Successfully parsed EPG: \(guide.channels.count) channels, \(guide.programs.count) programs")
            summary.finishedAt = Date()
            
            return (guide, summary)
            
        } catch {
            logError("Failed to fetch EPG: \(error)")
            summary.addFailure(forKey: .iptvGuides, value: "Failed to fetch EPG: \(error)")
            summary.finishedAt = Date()
            return (nil, summary)
        }
    }
    
    /// Fetches EPG data from EPG.pw for all channels
    /// - Returns: Tuple containing the parsed guide and fetch summary
    func fetchGlobalEPG() async -> (guide: XMLTVGuide?, summary: FetchSummary) {
        return await fetchEPG(from: "https://epg.pw/xmltv/epg.xml.gz")
    }
    
    /// Fetches EPG data from EPG.pw for a specific country
    /// - Parameter countryCode: Two-letter country code (e.g., "US", "GB", "CA")
    /// - Returns: Tuple containing the parsed guide and fetch summary
    func fetchCountryEPG(countryCode: String) async -> (guide: XMLTVGuide?, summary: FetchSummary) {
        let url = "https://epg.pw/xmltv/epg_\(countryCode.uppercased()).xml.gz"
        return await fetchEPG(from: url)
    }
    
    /// Fetches EPG data from EPG.pw lite version (smaller file size)
    /// - Returns: Tuple containing the parsed guide and fetch summary
    func fetchLiteEPG() async -> (guide: XMLTVGuide?, summary: FetchSummary) {
        return await fetchEPG(from: "https://epg.pw/xmltv/epg_lite.xml.gz")
    }
}

// MARK: - XMLTV Parser

/// Parses XMLTV XML format into structured data
private class XMLTVParser: NSObject, XMLParserDelegate {
    
    private var channels: [XMLTVChannel] = []
    private var programs: [XMLTVProgram] = []
    
    private var currentElement: String = ""
    private var currentAttributes: [String: String] = [:]
    private var currentValue: String = ""
    
    // Channel parsing state
    private var currentChannelId: String?
    private var currentDisplayNames: [XMLTVDisplayName] = []
    private var currentIcons: [XMLTVIcon] = []
    private var currentUrls: [String] = []
    
    // program parsing state
    private var currentProgram: XMLTVProgramBuilder?
    
    func parse(_ data: Data) throws -> XMLTVGuide {
        channels.removeAll()
        programs.removeAll()
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            if let error = parser.parserError {
                throw error
            }
            throw NSError(domain: "XMLTVParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown parsing error"])
        }
        
        return XMLTVGuide(channels: channels, programs: programs)
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentAttributes = attributeDict
        currentValue = ""
        
        switch elementName {
            case "channel":
                currentChannelId = attributeDict["id"]
                currentDisplayNames.removeAll()
                currentIcons.removeAll()
                currentUrls.removeAll()
                
            case "programme":
                currentProgram = XMLTVProgramBuilder(
                    channel: attributeDict["channel"] ?? "",
                    start: attributeDict["start"] ?? "",
                    stop: attributeDict["stop"] ?? ""
                )
                
            case "icon":
                if let src = attributeDict["src"] {
                    let icon = XMLTVIcon(
                        src: src,
                        width: Int(attributeDict["width"] ?? ""),
                        height: Int(attributeDict["height"] ?? "")
                    )
                    
                    if currentProgram != nil {
                        currentProgram?.icons.append(icon)
                    } else if currentChannelId != nil {
                        currentIcons.append(icon)
                    }
                }
                
            default:
                break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        switch elementName {
            case "channel":
                if let channelId = currentChannelId {
                    let channel = XMLTVChannel(
                        id: channelId,
                        displayNames: currentDisplayNames,
                        icons: currentIcons.isEmpty ? nil : currentIcons,
                        urls: currentUrls.isEmpty ? nil : currentUrls
                    )
                    channels.append(channel)
                }
                currentChannelId = nil
                
            case "display-name":
                if currentChannelId != nil {
                    let displayName = XMLTVDisplayName(value: currentValue, lang: currentAttributes["lang"])
                    currentDisplayNames.append(displayName)
                }
                
            case "url":
                if currentChannelId != nil, !currentValue.isEmpty {
                    currentUrls.append(currentValue)
                }
                
            case "programme":
                if let builder = currentProgram {
                    programs.append(builder.build())
                }
                currentProgram = nil
                
            case "title":
                let title = XMLTVTitle(value: currentValue, lang: currentAttributes["lang"])
                currentProgram?.titles.append(title)
                
            case "sub-title":
                let subTitle = XMLTVTitle(value: currentValue, lang: currentAttributes["lang"])
                currentProgram?.subTitles.append(subTitle)
                
            case "desc":
                let desc = XMLTVDescription(value: currentValue, lang: currentAttributes["lang"])
                currentProgram?.descriptions.append(desc)
                
            case "category":
                let category = XMLTVCategory(value: currentValue, lang: currentAttributes["lang"])
                currentProgram?.categories.append(category)
                
            case "date":
                currentProgram?.date = currentValue
                
            default:
                break
        }
        
        currentValue = ""
    }
}

// MARK: - program Builder Helper

private struct XMLTVProgramBuilder {
    let channel: String
    let start: String
    let stop: String
    var titles: [XMLTVTitle] = []
    var subTitles: [XMLTVTitle] = []
    var descriptions: [XMLTVDescription] = []
    var categories: [XMLTVCategory] = []
    var icons: [XMLTVIcon] = []
    var date: String?
    
    func build() -> XMLTVProgram {
        XMLTVProgram(
            channel: channel,
            start: start,
            stop: stop,
            titles: titles,
            subTitles: subTitles.isEmpty ? nil : subTitles,
            descriptions: descriptions.isEmpty ? nil : descriptions,
            categories: categories.isEmpty ? nil : categories,
            icons: icons.isEmpty ? nil : icons,
            episodeNum: nil,
            date: date,
            credits: nil,
            rating: nil,
            starRating: nil,
            previouslyShown: nil,
            premiere: nil,
            new: nil
        )
    }
}
