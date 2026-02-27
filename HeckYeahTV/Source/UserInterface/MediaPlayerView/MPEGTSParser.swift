//
//  MPEGTSParser.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/25/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Parses MPEG-TS (MPEG Transport Stream) data to extract codec and stream information.
///
/// This parser analyzes MPEG-TS streams to identify video and audio codecs, their packet identifiers (PIDs),
/// and stream types. It implements the ISO/IEC 13818-1 standard for MPEG-2 Transport Streams.
///
/// ## MPEG-TS Glossary
///
/// **MPEG-TS** - MPEG Transport Stream
/// - Container format for transmitting audio, video, and data
/// - Used by broadcast systems (ATSC, DVB), HDHomeRun devices, and some streaming protocols
/// - Fixed 188-byte packets with error correction and multiplexing capabilities
///
/// **TS Packet** - Transport Stream Packet
/// - Fixed 188-byte unit that carries elementary stream data
/// - Starts with sync byte (0x47) followed by header and payload
/// - Can carry partial ES data; multiple packets reassemble into complete frames
///
/// **PID** - Packet Identifier
/// - 13-bit identifier (0-8191) that labels each packet's content type
/// - Allows demultiplexing of multiple streams from a single transport stream
/// - Reserved PIDs: 0x0000 (PAT), 0x0001 (CAT), 0x0010-0x1FFE (PMT), 0x1FFF (null packets)
///
/// **PAT** - Program Association Table (PID 0x0000)
/// - Master index that lists all programs in the transport stream
/// - Maps program numbers to their PMT PIDs
/// - Typically the first table parsed to discover available programs
///
/// **PMT** - Program Map Table
/// - Describes a single program's elementary streams
/// - Lists video, audio, subtitle, and data streams with their PIDs and codec types
/// - Contains stream_type codes that identify codecs (e.g., 0x1B = H.264, 0x0F = AAC)
///
/// **ES** - Elementary Stream
/// - Single continuous stream of video, audio, or data
/// - Examples: H.264 video ES, AC-3 audio ES, subtitle ES
/// - Packetized into TS packets via PES (Packetized Elementary Stream) format
///
/// **PCR** - Program Clock Reference
/// - Timestamp used for synchronizing decoder clocks with encoder
/// - Helps maintain audio/video sync during playback
/// - Embedded in adaptation field of certain TS packets
///
/// **Sync Byte** - 0x47
/// - First byte of every MPEG-TS packet
/// - Used to locate packet boundaries in the stream
/// - If missing, the stream is corrupted or misaligned
///
/// **Stream Type** - Codec Identifier
/// - 8-bit value in PMT that specifies the codec of an elementary stream
/// - Common values:
///   - Video: 0x01 (MPEG-1), 0x02 (MPEG-2), 0x1B (H.264/AVC), 0x24 (H.265/HEVC)
///   - Audio: 0x03/0x04 (MPEG Audio), 0x0F (AAC-ADTS), 0x11 (AAC-LATM), 0x81 (AC-3/Dolby Digital)
///
/// **Adaptation Field**
/// - Optional header extension in TS packet (bits in header control its presence)
/// - Carries PCR timestamps, splice points, and other metadata
/// - Allows variable payload size within fixed 188-byte packet structure
///
/// ## Audio/Video Codec Abbreviations
///
/// **AVC** - Advanced Video Coding (H.264)
/// - Modern video compression standard, widely supported
/// - Efficient compression for HD video, used by Blu-ray, streaming services, broadcasts
/// - Stream type: 0x1B in MPEG-TS
///
/// **HEVC** - High Efficiency Video Coding (H.265)
/// - Next-generation video codec, successor to H.264
/// - ~50% better compression than H.264 at same quality
/// - Used for 4K/8K content, requires more processing power to decode
/// - Stream type: 0x24 in MPEG-TS
///
/// **AAC** - Advanced Audio Coding
/// - Modern audio compression format, successor to MP3
/// - Better sound quality than MP3 at same bitrate
/// - Standard audio codec for streaming (YouTube, Apple Music, etc.)
/// - Two transport formats: AAC-ADTS and AAC-LATM
///
/// **AAC-ADTS** - AAC with Audio Data Transport Stream
/// - AAC format with frame headers for streaming/broadcasting
/// - Each frame is self-contained with sync word and configuration
/// - Used in MPEG-TS broadcasts and streaming
/// - Stream type: 0x0F in MPEG-TS
///
/// **AAC-LATM** - AAC with Low Overhead Audio Transport Multiplex
/// - More efficient AAC framing with lower overhead than ADTS
/// - Configuration sent separately, frames don't repeat metadata
/// - Used in mobile broadcasting and some IPTV systems
/// - Stream type: 0x11 in MPEG-TS
///
/// **AC-3** - Audio Codec 3 (Dolby Digital)
/// - Surround sound audio format developed by Dolby
/// - Supports up to 5.1 channels (6 discrete channels)
/// - Standard for DVD, Blu-ray, ATSC broadcasts, and HDHomeRun devices
/// - Stream type: 0x81 in MPEG-TS
///
/// **E-AC-3** - Enhanced AC-3 (Dolby Digital Plus)
/// - Improved version of AC-3 with better compression
/// - Supports up to 15.1 channels, higher bitrates
/// - Used by streaming services (Netflix, Disney+) and Blu-ray
/// - Stream type: 0x87 in MPEG-TS
///
/// ## Streaming Protocol Abbreviations
///
/// **HLS** - HTTP Live Streaming
/// - Adaptive bitrate streaming protocol developed by Apple
/// - Breaks video into small chunks (.ts segments) with .m3u8 playlist
/// - Dynamically adjusts quality based on network conditions
/// - Supports ad insertion via EXT-X-DISCONTINUITY tags
/// - Widely supported across devices and platforms
///
/// **DASH** - Dynamic Adaptive Streaming over HTTP
/// - Open standard alternative to HLS
/// - Uses .mpd (Media Presentation Description) manifest files
/// - Similar adaptive bitrate streaming capabilities
/// - More flexible container support (MP4, WebM)
///
/// **RTSP** - Real Time Streaming Protocol
/// - Network control protocol for streaming media servers
/// - Used for live streams, security cameras, video conferencing
/// - Typically paired with RTP (Real-time Transport Protocol)
///
/// **RTP** - Real-time Transport Protocol
/// - Protocol for delivering audio/video over IP networks
/// - Used for live streaming, VoIP, video conferencing
/// - Often carried within RTSP sessions
///
/// ## Container Format Abbreviations
///
/// **MP4** - MPEG-4 Part 14
/// - Modern container format based on QuickTime
/// - Supports H.264/H.265 video and AAC audio
/// - Used for downloaded content, streaming segments
///
/// **MKV** - Matroska Video
/// - Open-source container supporting virtually any codec
/// - Popular for high-quality video distribution
/// - Not natively supported by most hardware players
///
/// **FLV** - Flash Video
/// - Legacy container format for Adobe Flash
/// - Historically used for web video (YouTube, pre-2015)
/// - Being phased out in favor of HLS/DASH
///
/// ## Responsibilities:
/// - Parse MPEG-TS packets from a streaming URL
/// - Extract Program Association Table (PAT) to locate the Program Map Table
/// - Parse Program Map Table (PMT) to identify elementary streams
/// - Detect video codecs (H.264, H.265, MPEG-2, etc.)
/// - Detect audio codecs (AAC, AC-3, MPEG Audio, etc.)
/// - Provide stream metadata including PIDs and codec types
///
/// ## How it works:
/// 1. Downloads MPEG-TS packets from a URL
/// 2. Synchronizes to the MPEG-TS stream using the sync byte (0x47)
/// 3. Parses PAT to find the PMT PID
/// 4. Parses PMT to discover video and audio elementary streams
/// 5. Returns comprehensive stream information including codec types and PIDs
///
/// **Usage:**
/// ```swift
/// let parser = MPEGTSParser()
/// let streamInfo = try await parser.analyze(url: tsStreamURL)
/// print(streamInfo.description)
/// ```
class MPEGTSParser {
    
    // MARK: - MPEG-TS Constants
    
    /// Synchronization byte that marks the start of each MPEG-TS packet (0x47)
    private static let syncByte: UInt8 = 0x47
    
    /// Standard MPEG-TS packet size in bytes
    private static let packetSize = 188
    
    /// Packet Identifier (PID) for the Program Association Table (PAT)
    /// The PAT is always at PID 0x0000 and contains the mapping of programs to PMT PIDs
    private static let patPID: UInt16 = 0x0000
    
    // MARK: - Stream Information Properties
    
    /// PID of the Program Map Table, discovered from the PAT
    private var programMapPID: UInt16?
    
    /// PID of the video elementary stream, discovered from the PMT
    private var videoPID: UInt16?
    
    /// PID of the audio elementary stream, discovered from the PMT
    private var audioPID: UInt16?
    
    /// Stream type identifier for the video stream (e.g., 0x1B for H.264)
    private var videoStreamType: UInt8?
    
    /// Stream type identifier for the audio stream (e.g., 0x0F for AAC)
    private var audioStreamType: UInt8?
    
    /// All elementary streams found in the PMT (for debugging/analysis)
    private var allStreams: [(pid: UInt16, streamType: UInt8)] = []
    
    /// DRM/Encryption detection
    private var isEncrypted = false
    private var caSystemIDs: [UInt16] = []
    private var scrambledPacketsFound = false
    
    // MARK: - Public Methods
    
    /// Analyzes an MPEG-TS stream from a URL to extract codec and stream information.
    ///
    /// **Responsibility:**
    /// Downloads and parses the initial portion of an MPEG-TS stream to identify video and audio codecs,
    /// PIDs, and stream types. This method is the primary entry point for stream analysis.
    ///
    /// **How it works:**
    /// 1. Initiates an HTTP request to download the MPEG-TS stream
    /// 2. Validates the HTTP response status
    /// 3. Processes incoming bytes one at a time, building up complete packets
    /// 4. Synchronizes to the stream by finding the sync byte (0x47)
    /// 5. Parses up to 100 packets to discover PAT and PMT information
    /// 6. Extracts video and audio stream metadata
    /// 7. Returns early once all necessary information is found
    ///
    /// **Process Flow:**
    /// - Reads bytes asynchronously from the URL
    /// - Accumulates bytes in a buffer until a complete 188-byte packet is available
    /// - Aligns to packet boundaries by searching for the sync byte
    /// - Delegates packet parsing to `parsePacket(_:)`
    /// - Stops after analyzing 100 packets or when video/audio info is complete
    ///
    /// - Parameter url: The URL of the MPEG-TS stream to analyze
    /// - Returns: A `TSStreamInfo` struct containing detected codec information, PIDs, and stream types
    /// - Throws: An error if the HTTP request fails or if the stream cannot be accessed
    func analyze(url: URL) async throws -> TSStreamInfo {
        print("MPEGTSParser: Starting analysis of \(url.absoluteString)")
        
        // Create a custom URLSession with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        let session = URLSession(configuration: config)
        
        let asyncBytes: URLSession.AsyncBytes
        let response: URLResponse
        
        do {
            (asyncBytes, response) = try await session.bytes(from: url)
        } catch {
            print("MPEGTSParser: ERROR - Failed to connect to URL: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("MPEGTSParser: URLError code: \(urlError.code.rawValue)")
                print("MPEGTSParser: URLError description: \(urlError.localizedDescription)")
            }
            throw error
        }
        
        // Check if it's an HTTP response and validate status code
        if let httpResponse = response as? HTTPURLResponse {
            print("MPEGTSParser: HTTP Status Code = \(httpResponse.statusCode)")
            print("MPEGTSParser: Content-Type = \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown")")
            
            if let server = httpResponse.value(forHTTPHeaderField: "Server") {
                print("MPEGTSParser: Server = \(server)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusDescription = httpStatusDescription(httpResponse.statusCode)
                let errorMsg = "HTTP request failed with status code \(httpResponse.statusCode) (\(statusDescription))"
                print("MPEGTSParser: ERROR - \(errorMsg)")
                
                // Provide helpful suggestions based on status code
                switch httpResponse.statusCode {
                    case 404:
                        print("MPEGTSParser: SUGGESTION - Stream not found. Check if the URL path is correct.")
                    case 403:
                        print("MPEGTSParser: SUGGESTION - Access forbidden. Check authentication or IP restrictions.")
                    case 503:
                        print("MPEGTSParser: SUGGESTION - Service unavailable. The streaming server may be down or overloaded. Try again later.")
                    case 500...599:
                        print("MPEGTSParser: SUGGESTION - Server error. Check the streaming server logs for issues.")
                    default:
                        break
                }
                
                throw NSError(domain: "MPEGTSParser", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: errorMsg,
                    NSLocalizedFailureReasonErrorKey: statusDescription
                ])
            }
        } else {
            // Non-HTTP response (file://, custom schemes, etc.)
            print("MPEGTSParser: Non-HTTP response type: \(type(of: response))")
        }
        
        var buffer = Data()
        var packetsAnalyzed = 0
        let maxPackets = 200 // Increased from 100 to analyze more packets if needed
        var pmtFound = false
        
        for try await byte in asyncBytes {
            buffer.append(byte)
            
            // Wait until we have at least one full packet
            while buffer.count >= Self.packetSize {
                // Find sync byte
                guard buffer.first == Self.syncByte else {
                    // Not aligned, drop first byte and try again
                    buffer.removeFirst()
                    continue
                }
                
                let packet = buffer.prefix(Self.packetSize)
                buffer.removeFirst(Self.packetSize)
                
                parsePacket(Data(packet))
                packetsAnalyzed += 1
                
                // Track if we've found and processed the PMT
                if programMapPID != nil && (videoPID != nil || audioPID != nil) {
                    pmtFound = true
                }
                
                // Early exit conditions (more flexible):
                // 1. Found PMT and at least one stream (video or audio), analyzed enough packets
                if pmtFound && packetsAnalyzed >= 50 {
                    print("MPEGTSParser: Analyzed \(packetsAnalyzed) packets, found stream info")
                    return buildStreamInfo()
                }
                
                // 2. Hard limit reached - return whatever we found
                if packetsAnalyzed >= maxPackets {
                    print("MPEGTSParser: Reached max packets (\(maxPackets)), returning available info")
                    return buildStreamInfo()
                }
            }
        }
        
        print("MPEGTSParser: Stream ended after \(packetsAnalyzed) packets")
        return buildStreamInfo()
    }
    
    // MARK: - Private Parsing Methods
    
    /// Parses a single MPEG-TS packet and routes it to the appropriate table parser.
    ///
    /// **Responsibility:**
    /// Validates packet structure, extracts the PID, handles adaptation fields, and routes packets
    /// to either PAT or PMT parsers based on their PID.
    ///
    /// **How it works:**
    /// 1. Validates packet size and sync byte
    /// 2. Extracts the 13-bit PID from bytes 1-2 of the packet
    /// 3. Checks the adaptation field control to determine payload location
    /// 4. Skips over adaptation field if present
    /// 5. Checks payload unit start indicator to identify table boundaries
    /// 6. Routes PAT packets (PID 0x0000) to `parsePAT(_:payloadStart:)`
    /// 7. Routes PMT packets to `parsePMT(_:payloadStart:)` once PMT PID is known
    ///
    /// **Packet Structure (188 bytes total):**
    /// - **Byte 0**: Sync byte (0x47) - marks packet boundary
    /// - **Byte 1**:
    ///   - Bit 7: Transport Error Indicator (TEI)
    ///   - Bit 6: Payload Unit Start Indicator (PUSI) - indicates start of PES packet or PSI table
    ///   - Bit 5: Transport Priority
    ///   - Bits 4-0: Upper 5 bits of PID
    /// - **Byte 2**: Lower 8 bits of PID (combined with byte 1 = 13-bit PID)
    /// - **Byte 3**:
    ///   - Bits 7-6: Transport Scrambling Control
    ///   - Bits 5-4: Adaptation Field Control (01=payload only, 10=adaptation only, 11=both)
    ///   - Bits 3-0: Continuity Counter (wraps 0-15)
    /// - **Byte 4**: Adaptation field length (if adaptation field present)
    /// - **Byte 5+**: Adaptation field data (optional timing, PCR, flags)
    /// - **Remaining bytes**: Payload data (PSI tables or PES packets)
    ///
    /// - Parameter packet: A 188-byte MPEG-TS packet to parse
    private func parsePacket(_ packet: Data) {
        guard packet.count >= Self.packetSize, packet[0] == Self.syncByte else {
            return
        }
        
        // Extract PID (13 bits from bytes 1-2)
        let pidHigh = UInt16(packet[1] & 0x1F)
        let pidLow = UInt16(packet[2])
        let pid = (pidHigh << 8) | pidLow
        
        // Check for scrambling (Transport Scrambling Control bits 7-6 of byte 3)
        let scramblingControl = (packet[3] & 0xC0) >> 6
        if scramblingControl != 0 {
            if !scrambledPacketsFound {
                print("MPEGTSParser: 🔒 ENCRYPTION DETECTED - Scrambled packet found (PID: \(pid), Scrambling: \(scramblingControl))")
                scrambledPacketsFound = true
                isEncrypted = true
            }
        }
        
        // Check adaptation field control
        let adaptationFieldControl = (packet[3] & 0x30) >> 4
        var payloadStart = 4
        
        // Skip adaptation field if present
        if adaptationFieldControl == 2 || adaptationFieldControl == 3 {
            let adaptationFieldLength = Int(packet[4])
            payloadStart = 5 + adaptationFieldLength
        }
        
        // Check if payload unit start indicator is set
        let payloadUnitStart = (packet[1] & 0x40) != 0
        
        guard payloadStart < packet.count else { return }
        
        if pid == Self.patPID && payloadUnitStart {
            parsePAT(packet, payloadStart: payloadStart)
        } else if let pmtPID = programMapPID, pid == pmtPID && payloadUnitStart {
            parsePMT(packet, payloadStart: payloadStart)
        }
    }
    
    /// Parses the Program Association Table (PAT) to discover the PMT PID.
    ///
    /// **Responsibility:**
    /// Extracts the Program Map Table PID from the PAT, which is the first step in discovering
    /// elementary stream information. The PAT maps program numbers to their PMT PIDs.
    ///
    /// **How it works:**
    /// 1. Locates the table start position using the pointer field
    /// 2. Validates the table ID (must be 0x00 for PAT)
    /// 3. Extracts the section length to determine table boundaries
    /// 4. Iterates through program entries (4 bytes each)
    /// 5. Finds the first non-zero program number and extracts its PMT PID
    /// 6. Stores the PMT PID for use in subsequent packet parsing
    ///
    /// **PAT Structure:**
    /// - Pointer field: Offset to table start
    /// - Table ID: 0x00 (identifies as PAT)
    /// - Section length: Total length of the table
    /// - Program entries: (program_number: 16 bits, PMT_PID: 13 bits) repeated
    /// - CRC: 4 bytes at the end
    ///
    /// **Note:** Program number 0 refers to the Network Information Table (NIT), which is ignored.
    ///
    /// - Parameter packet: The MPEG-TS packet containing PAT data
    /// - Parameter payloadStart: Byte offset where the payload begins in the packet
    private func parsePAT(_ packet: Data, payloadStart: Int) {
        guard payloadStart + 1 < packet.count else { return }
        
        let pointerField = Int(packet[payloadStart])
        let tableStart = payloadStart + 1 + pointerField
        
        guard tableStart + 12 < packet.count else { return }
        
        let tableId = packet[tableStart]
        guard tableId == 0x00 else { return } // PAT table ID
        
        let sectionLength = Int((UInt16(packet[tableStart + 1] & 0x0F) << 8) | UInt16(packet[tableStart + 2]))
        
        var offset = tableStart + 8 // Skip to program list
        let endOffset = min(tableStart + 3 + sectionLength - 4, packet.count) // -4 for CRC
        
        while offset + 4 <= endOffset {
            let programNumber = (UInt16(packet[offset]) << 8) | UInt16(packet[offset + 1])
            let pmtPID = ((UInt16(packet[offset + 2] & 0x1F) << 8) | UInt16(packet[offset + 3]))
            
            if programNumber != 0 {
                programMapPID = pmtPID
                print("MPEGTSParser: Found PMT PID = \(pmtPID)")
                return
            }
            
            offset += 4
        }
    }
    
    /// Parses the Program Map Table (PMT) to discover elementary stream PIDs and types.
    ///
    /// **Responsibility:**
    /// Extracts detailed information about video and audio elementary streams, including their PIDs
    /// and stream type identifiers. This is the final step in discovering codec information.
    ///
    /// **How it works:**
    /// 1. Locates the table start position using the pointer field
    /// 2. Validates the table ID (must be 0x02 for PMT)
    /// 3. Extracts section length and program info length
    /// 4. Skips over program-level descriptors
    /// 5. Iterates through elementary stream entries
    /// 6. For each stream:
    ///    - Extracts stream type (identifies codec)
    ///    - Extracts elementary PID (PID = 'Packet Identifier' for the elementary stream)
    ///    - Determines if it's a video or audio stream
    ///    - Stores the first video and audio stream found
    /// 7. Continues until all streams are processed or packet ends
    ///
    /// **PMT Structure:**
    /// - Pointer field: Offset to table start
    /// - Table ID: 0x02 (identifies as PMT)
    /// - Section length: Total length of the table
    /// - Program info length: Length of program-level descriptors
    /// - Elementary stream entries: (stream_type: 8 bits, elementary_PID: 13 bits, ES_info_length: 12 bits) repeated
    /// - CRC: 4 bytes at the end
    ///
    /// **Stream Type Examples:**
    /// - 0x1B: H.264/AVC video
    /// - 0x24: H.265/HEVC video
    /// - 0x0F: AAC audio
    /// - 0x81: AC-3 audio
    ///
    /// - Parameter packet: The MPEG-TS packet containing PMT data
    /// - Parameter payloadStart: Byte offset where the payload begins in the packet
    private func parsePMT(_ packet: Data, payloadStart: Int) {
        guard payloadStart + 1 < packet.count else { return }
        
        let pointerField = Int(packet[payloadStart])
        let tableStart = payloadStart + 1 + pointerField
        
        guard tableStart + 12 < packet.count else { return }
        
        let tableId = packet[tableStart]
        guard tableId == 0x02 else { return } // PMT table ID
        
        let sectionLength = Int((UInt16(packet[tableStart + 1] & 0x0F) << 8) | UInt16(packet[tableStart + 2]))
        let programInfoLength = Int((UInt16(packet[tableStart + 10] & 0x0F) << 8) | UInt16(packet[tableStart + 11]))
        
        print("MPEGTSParser: Parsing PMT - Section length: \(sectionLength), Program info length: \(programInfoLength)")
        
        // Parse program-level descriptors (look for CA descriptors)
        if programInfoLength > 0 {
            parseDescriptors(packet: packet, descriptorsStart: tableStart + 12, descriptorsLength: programInfoLength, context: "Program")
        }
        
        var offset = tableStart + 12 + programInfoLength
        let endOffset = min(tableStart + 3 + sectionLength - 4, packet.count)
        
        while offset + 5 <= endOffset {
            let streamType = packet[offset]
            let elementaryPID = ((UInt16(packet[offset + 1] & 0x1F) << 8) | UInt16(packet[offset + 2]))
            let esInfoLength = Int((UInt16(packet[offset + 3] & 0x0F) << 8) | UInt16(packet[offset + 4]))
            
            // Track all streams found
            allStreams.append((pid: elementaryPID, streamType: streamType))
            
            // Classify and capture streams
            if isVideoStreamType(streamType) {
                if videoPID == nil {
                    videoPID = elementaryPID
                    videoStreamType = streamType
                    print("MPEGTSParser: ✓ Found VIDEO stream - Type: 0x\(String(format: "%02X", streamType)) [\(codecNameFromStreamType(streamType))], PID: \(elementaryPID)")
                }
            } else if isAudioStreamType(streamType) {
                if audioPID == nil {
                    audioPID = elementaryPID
                    audioStreamType = streamType
                    print("MPEGTSParser: ✓ Found AUDIO stream - Type: 0x\(String(format: "%02X", streamType)) [\(codecNameFromStreamType(streamType))], PID: \(elementaryPID)")
                }
            } else {
                // If we haven't found video or audio yet, try to guess based on stream type value
                // Some streams use non-standard type codes
                print("MPEGTSParser: ? Found UNKNOWN stream - Type: 0x\(String(format: "%02X", streamType)) [\(codecNameFromStreamType(streamType))], PID: \(elementaryPID)")
                
                // Heuristic: if no video found yet and type seems video-like, capture it
                if videoPID == nil && streamType < 0x80 {
                    print("MPEGTSParser:   → Treating as potential VIDEO stream (heuristic)")
                    videoPID = elementaryPID
                    videoStreamType = streamType
                }
                // Heuristic: if no audio found yet and type seems audio-like
                else if audioPID == nil && streamType >= 0x80 {
                    print("MPEGTSParser:   → Treating as potential AUDIO stream (heuristic)")
                    audioPID = elementaryPID
                    audioStreamType = streamType
                }
            }
            
            // Parse elementary stream descriptors (look for CA descriptors)
            if esInfoLength > 0 && offset + 5 + esInfoLength <= packet.count {
                parseDescriptors(packet: packet, descriptorsStart: offset + 5, descriptorsLength: esInfoLength, context: "ES PID \(elementaryPID)")
            }
            
            offset += 5 + esInfoLength
        }
        
        print("MPEGTSParser: PMT parsing complete - Found \(allStreams.count) total streams")
    }
    
    /// Parses descriptor loop to find CA (Conditional Access) descriptors
    private func parseDescriptors(packet: Data, descriptorsStart: Int, descriptorsLength: Int, context: String) {
        var offset = descriptorsStart
        let endOffset = min(descriptorsStart + descriptorsLength, packet.count)
        
        while offset + 2 <= endOffset {
            guard offset < packet.count else { break }
            
            let descriptorTag = packet[offset]
            let descriptorLength = Int(packet[offset + 1])
            
            // CA descriptor tag is 0x09
            if descriptorTag == 0x09 && offset + 2 + descriptorLength <= packet.count {
                // CA descriptor format:
                // - Tag: 0x09 (1 byte)
                // - Length (1 byte)
                // - CA System ID (2 bytes)
                // - CA PID (13 bits)
                // - Private data (variable)
                
                if descriptorLength >= 4 {
                    let caSystemID = (UInt16(packet[offset + 2]) << 8) | UInt16(packet[offset + 3])
                    let caPID = ((UInt16(packet[offset + 4] & 0x1F) << 8) | UInt16(packet[offset + 5]))
                    
                    if !caSystemIDs.contains(caSystemID) {
                        caSystemIDs.append(caSystemID)
                        isEncrypted = true
                        print("MPEGTSParser: 🔒 CA DESCRIPTOR FOUND (\(context)) - CA System ID: 0x\(String(format: "%04X", caSystemID)) [\(caSystemName(caSystemID))], CA PID: \(caPID)")
                    }
                }
            }
            
            offset += 2 + descriptorLength
        }
    }
    
    /// Returns a human-readable description of an HTTP status code
    private func httpStatusDescription(_ statusCode: Int) -> String {
        switch statusCode {
                // 2xx Success
            case 200: return "OK"
            case 206: return "Partial Content"
                
                // 3xx Redirection
            case 301: return "Moved Permanently"
            case 302: return "Found"
            case 304: return "Not Modified"
                
                // 4xx Client Errors
            case 400: return "Bad Request"
            case 401: return "Unauthorized"
            case 403: return "Forbidden"
            case 404: return "Not Found"
            case 408: return "Request Timeout"
            case 429: return "Too Many Requests"
                
                // 5xx Server Errors
            case 500: return "Internal Server Error"
            case 501: return "Not Implemented"
            case 502: return "Bad Gateway"
            case 503: return "Service Unavailable"
            case 504: return "Gateway Timeout"
                
            default:
                if (200...299).contains(statusCode) {
                    return "Success"
                } else if (300...399).contains(statusCode) {
                    return "Redirection"
                } else if (400...499).contains(statusCode) {
                    return "Client Error"
                } else if (500...599).contains(statusCode) {
                    return "Server Error"
                }
                return "Unknown Status"
        }
    }
    
    /// Returns the name of the CA (Conditional Access) system based on its ID
    private func caSystemName(_ caSystemID: UInt16) -> String {
        switch caSystemID {
                // Common DRM/CA Systems
            case 0x0100...0x01FF: return "SECA/MediaGuard"
            case 0x0500...0x05FF: return "Viaccess"
            case 0x0600...0x06FF: return "Irdeto"
            case 0x0900...0x09FF: return "NDS/VideoGuard"
            case 0x0B00...0x0BFF: return "Conax"
            case 0x0D00...0x0DFF: return "CryptoWorks"
            case 0x1800...0x18FF: return "Nagravision"
            case 0x4A60...0x4A6F: return "DRM Today (SkillSoft)"
            case 0x4AD4...0x4AD5: return "Advanced Digital Broadcast"
            case 0x4AE0...0x4AE1: return "Irdeto BISS"
                
                // Modern Streaming DRM
            case 0x6400: return "PlayReady"
            case 0x6500: return "Widevine"
            case 0x6600: return "FairPlay"
                
            default:
                if caSystemID >= 0x0A00 && caSystemID <= 0x0AFF {
                    return "Nokia CA"
                } else if caSystemID >= 0x4A00 && caSystemID <= 0x4AFF {
                    return "Logiways/Thales"
                }
                return "Unknown CA System"
        }
    }
    
    // MARK: - Stream Type Detection
    
    /// Determines if a stream type identifier represents a video codec.
    ///
    /// **Responsibility:**
    /// Identifies video streams by comparing the stream type byte against known video codec identifiers
    /// defined in the MPEG-TS specification.
    ///
    /// **How it works:**
    /// Checks the stream type against a list of standardized video codec identifiers:
    /// - 0x01: MPEG-1 Video
    /// - 0x02: MPEG-2 Video
    /// - 0x10: MPEG-4 Part 2 Video
    /// - 0x1B: H.264/AVC (most common for modern streams)
    /// - 0x24: H.265/HEVC (newer high-efficiency codec)
    /// - 0x42: Chinese AVS Video
    /// - 0xD1: BBC Dirac (VC-2)
    /// - 0xEA: Microsoft VC-1
    ///
    /// - Parameter type: The 8-bit stream type identifier from the PMT
    /// - Returns: `true` if the stream type represents a video codec, `false` otherwise
    private func isVideoStreamType(_ type: UInt8) -> Bool {
        switch type {
            case 0x01, 0x02: return true // MPEG-1, MPEG-2 Video
            case 0x10: return true       // MPEG-4 Part 2 Video
            case 0x1B: return true       // H.264 / AVC
            case 0x24: return true       // H.265 / HEVC
            case 0x42: return true       // Chinese AVS Video
            case 0xD1: return true       // BBC Dirac (VC-2)
            case 0xEA: return true       // Microsoft VC-1
            default: return false
        }
    }
    
    /// Determines if a stream type identifier represents an audio codec.
    ///
    /// **Responsibility:**
    /// Identifies audio streams by comparing the stream type byte against known audio codec identifiers
    /// defined in the MPEG-TS specification.
    ///
    /// **How it works:**
    /// Checks the stream type against a list of standardized audio codec identifiers:
    /// - 0x03: MPEG-1 Audio (MP3)
    /// - 0x04: MPEG-2 Audio
    /// - 0x06: Private data (often AC-3, DTS, or other proprietary formats)
    /// - 0x0F: AAC with ADTS framing (common for streaming)
    /// - 0x11: AAC with LATM framing
    /// - 0x81: AC-3 (Dolby Digital)
    /// - 0x82: DTS
    /// - 0x83-0x86: TrueHD and DTS-HD variants
    /// - 0x87: E-AC-3 (Dolby Digital Plus)
    /// - 0xA1-0xA2: DVB variants of AC-3/DTS
    /// - 0xAC: AC-4 (Dolby AC-4)
    ///
    /// - Parameter type: The 8-bit stream type identifier from the PMT
    /// - Returns: `true` if the stream type represents an audio codec, `false` otherwise
    private func isAudioStreamType(_ type: UInt8) -> Bool {
        switch type {
            case 0x03, 0x04: return true // MPEG-1, MPEG-2 Audio
            case 0x06: return true       // Private data (often used for AC-3, DTS, etc.)
            case 0x0F: return true       // AAC (ADTS)
            case 0x11: return true       // AAC (LATM)
            case 0x81: return true       // AC-3
            case 0x82: return true       // DTS
            case 0x83: return true       // TrueHD
            case 0x84: return true       // AC-3 (alternate)
            case 0x85, 0x86: return true // DTS-HD
            case 0x87: return true       // E-AC-3
            case 0xA1, 0xA2: return true // AC-3/DTS (DVB)
            case 0xAC: return true       // AC-4
            default: return false
        }
    }
    
    // MARK: - Stream Info Construction
    
    /// Constructs a `TSStreamInfo` struct from the parsed stream data.
    ///
    /// **Responsibility:**
    /// Aggregates all discovered stream information into a cohesive data structure that can be
    /// returned to the caller. Converts stream type identifiers into human-readable codec names.
    ///
    /// **How it works:**
    /// 1. Converts video stream type to a readable codec name (if found)
    /// 2. Converts audio stream type to a readable codec name (if found)
    /// 3. Creates and returns a `TSStreamInfo` struct containing:
    ///    - Video and audio codec names
    ///    - Raw stream type identifiers
    ///    - Video and audio PIDs
    ///
    /// **Note:** Fields will be `nil` if the corresponding stream was not detected during parsing.
    ///
    /// - Returns: A `TSStreamInfo` struct containing all discovered stream information
    private func buildStreamInfo() -> TSStreamInfo {
        let videoCodec = videoStreamType.map { codecNameFromStreamType($0) }
        let audioCodec = audioStreamType.map { codecNameFromStreamType($0) }
        
        // Log summary of what was found
        print("MPEGTSParser: ═══════════════════════════════════════")
        print("MPEGTSParser: Analysis Summary")
        print("MPEGTSParser: ═══════════════════════════════════════")
        if let vc = videoCodec, let vt = videoStreamType, let vp = videoPID {
            print("MPEGTSParser: VIDEO: \(vc) (Type: 0x\(String(format: "%02X", vt)), PID: \(vp))")
        } else {
            print("MPEGTSParser: VIDEO: Not detected")
        }
        if let ac = audioCodec, let at = audioStreamType, let ap = audioPID {
            print("MPEGTSParser: AUDIO: \(ac) (Type: 0x\(String(format: "%02X", at)), PID: \(ap))")
        } else {
            print("MPEGTSParser: AUDIO: Not detected")
        }
        
        // Encryption/DRM info
        if isEncrypted {
            print("MPEGTSParser: 🔒 ENCRYPTION: YES")
            if !caSystemIDs.isEmpty {
                print("MPEGTSParser: DRM Systems detected:")
                for (index, caID) in caSystemIDs.enumerated() {
                    print("MPEGTSParser:   [\(index + 1)] CA System ID: 0x\(String(format: "%04X", caID)) [\(caSystemName(caID))]")
                }
            }
            if scrambledPacketsFound {
                print("MPEGTSParser: Scrambled packets: DETECTED")
            }
        } else {
            print("MPEGTSParser: 🔓 ENCRYPTION: No (Clear stream)")
        }
        
        if !allStreams.isEmpty {
            print("MPEGTSParser: All streams found: \(allStreams.count)")
            for (index, stream) in allStreams.enumerated() {
                print("MPEGTSParser:   [\(index + 1)] PID: \(stream.pid), Type: 0x\(String(format: "%02X", stream.streamType)) [\(codecNameFromStreamType(stream.streamType))]")
            }
        }
        print("MPEGTSParser: ═══════════════════════════════════════")
        
        return TSStreamInfo(
            videoCodec: videoCodec,
            audioCodec: audioCodec,
            videoStreamType: videoStreamType,
            audioStreamType: audioStreamType,
            videoPID: videoPID,
            audioPID: audioPID,
            isEncrypted: isEncrypted,
            caSystemIDs: caSystemIDs,
            caSystemNames: caSystemIDs.map { caSystemName($0) }
        )
    }
    
    /// Converts a stream type identifier to a human-readable codec name.
    ///
    /// **Responsibility:**
    /// Provides user-friendly codec names for both video and audio stream types, making the
    /// stream information more understandable for logging and display purposes.
    ///
    /// **How it works:**
    /// Maps standardized MPEG-TS stream type identifiers to descriptive codec names:
    ///
    /// **Video Codecs:**
    /// - 0x01: MPEG-1 Video (legacy)
    /// - 0x02: MPEG-2 Video (DVD, broadcast TV)
    /// - 0x1B: H.264/AVC (modern streaming standard)
    /// - 0x24: H.265/HEVC (4K/8K efficient codec)
    ///
    /// **Audio Codecs:**
    /// - 0x03: MPEG-1 Audio (MP3)
    /// - 0x04: MPEG-2 Audio
    /// - 0x0F: AAC (ADTS) - common streaming audio
    /// - 0x11: AAC (LATM) - alternative AAC framing
    /// - 0x81: AC-3 (Dolby Digital) - surround sound
    /// - 0x87: E-AC-3 (Dolby Digital Plus) - enhanced surround
    /// - 0xAC: AC-4 (Dolby AC-4) - next-gen audio codec
    ///
    /// - Parameter type: The 8-bit stream type identifier from the PMT
    /// - Returns: A descriptive string naming the codec, or "Unknown" with hex code if unrecognized
    private func codecNameFromStreamType(_ type: UInt8) -> String {
        switch type {
                // Video codecs
            case 0x01: return "MPEG-1 Video"
            case 0x02: return "MPEG-2 Video"
            case 0x10: return "MPEG-4 Part 2 Video"
            case 0x1B: return "H.264 / AVC"
            case 0x24: return "H.265 / HEVC"
            case 0x42: return "AVS Video"
            case 0xD1: return "BBC Dirac (VC-2)"
            case 0xEA: return "VC-1"
                
                // Audio codecs
            case 0x03: return "MPEG-1 Audio"
            case 0x04: return "MPEG-2 Audio"
            case 0x06: return "Private Data (AC-3/DTS/Other)"
            case 0x0F: return "AAC (ADTS)"
            case 0x11: return "AAC (LATM)"
            case 0x81: return "AC-3 (Dolby Digital)"
            case 0x82: return "DTS"
            case 0x83: return "TrueHD (Dolby TrueHD)"
            case 0x84: return "AC-3 (Alternate)"
            case 0x85: return "DTS-HD"
            case 0x86: return "DTS-HD MA"
            case 0x87: return "E-AC-3 (Dolby Digital Plus)"
            case 0xA1: return "AC-3 (DVB)"
            case 0xA2: return "DTS (DVB)"
            case 0xAC: return "AC-4 (Dolby AC-4)"
                
            default: return "Unknown (0x\(String(format: "%02X", type)))"
        }
    }
}

// MARK: - Stream Information Model

/// Information about an MPEG-TS stream, including detected codecs and PIDs.
///
/// **Responsibility:**
/// Encapsulates all metadata extracted from an MPEG-TS stream analysis, providing both raw
/// stream identifiers and human-readable codec names. Includes convenience properties for
/// common stream compatibility checks.
///
/// **Usage:**
/// ```swift
/// let parser = MPEGTSParser()
/// let streamInfo = try await parser.analyze(url: tsURL)
///
/// print(streamInfo.description)  // "Video: H.264/AVC (PID: 256), Audio: AAC (ADTS) (PID: 257)"
///
/// if streamInfo.isH264WithAAC {
///     print("Compatible with HLS streaming")
/// }
/// ```
struct TSStreamInfo {
    /// Human-readable name of the video codec (e.g., "H.264/AVC"), or `nil` if no video stream detected
    let videoCodec: String?
    
    /// Human-readable name of the audio codec (e.g., "AAC (ADTS)"), or `nil` if no audio stream detected
    let audioCodec: String?
    
    /// Raw stream type identifier for video (e.g., 0x1B for H.264), or `nil` if no video stream detected
    let videoStreamType: UInt8?
    
    /// Raw stream type identifier for audio (e.g., 0x0F for AAC), or `nil` if no audio stream detected
    let audioStreamType: UInt8?
    
    /// Packet Identifier (PID) for the video elementary stream, or `nil` if no video stream detected
    let videoPID: UInt16?
    
    /// Packet Identifier (PID) for the audio elementary stream, or `nil` if no audio stream detected
    let audioPID: UInt16?
    
    /// Indicates whether the stream is encrypted/scrambled
    let isEncrypted: Bool
    
    /// Conditional Access (CA) System IDs detected in the stream (DRM/encryption systems)
    let caSystemIDs: [UInt16]
    
    /// Human-readable names of the CA systems detected
    let caSystemNames: [String]
    
    /// A formatted description of the detected streams.
    ///
    /// **Responsibility:**
    /// Provides a human-readable summary of the stream information suitable for logging or display.
    ///
    /// **How it works:**
    /// Combines video and audio codec information with their PIDs into a comma-separated string.
    /// Returns "No streams detected" if neither video nor audio streams were found.
    ///
    /// **Example outputs:**
    /// - "Video: H.264/AVC (PID: 256), Audio: AAC (ADTS) (PID: 257)"
    /// - "Video: H.265/HEVC (PID: 100)"
    /// - "Audio: AC-3 (Dolby Digital) (PID: 300)"
    /// - "No streams detected"
    var description: String {
        var parts: [String] = []
        
        if let video = videoCodec {
            let pid = videoPID.map { " (PID: \($0))" } ?? ""
            parts.append("Video: \(video)\(pid)")
        }
        
        if let audio = audioCodec {
            let pid = audioPID.map { " (PID: \($0))" } ?? ""
            parts.append("Audio: \(audio)\(pid)")
        }
        
        if isEncrypted {
            if caSystemNames.isEmpty {
                parts.append("🔒 Encrypted (Scrambled)")
            } else {
                parts.append("🔒 Encrypted (\(caSystemNames.joined(separator: ", ")))")
            }
        }
        
        return parts.isEmpty ? "No streams detected" : parts.joined(separator: ", ")
    }
    
    /// Indicates whether the stream uses H.264 video with AAC audio.
    ///
    /// **Responsibility:**
    /// Provides a quick check for the most common HLS-compatible codec combination.
    ///
    /// **How it works:**
    /// Checks if the video stream type is 0x1B (H.264/AVC) and the audio stream type is
    /// either 0x0F (AAC with ADTS) or 0x11 (AAC with LATM). This combination is widely
    /// supported for HLS streaming on Apple platforms.
    ///
    /// - Returns: `true` if both H.264 video and AAC audio are present, `false` otherwise
    var isH264WithAAC: Bool {
        videoStreamType == 0x1B && (audioStreamType == 0x0F || audioStreamType == 0x11)
    }
    
    /// Indicates whether the stream is compatible with AVPlayer on Apple platforms.
    ///
    /// **Responsibility:**
    /// Determines if AVPlayer can play the stream based on its video and audio codecs.
    ///
    /// **How it works:**
    /// AVPlayer has limited codec support:
    /// - **Supported Video**: H.264 (0x1B), H.265 (0x24)
    /// - **Supported Audio**: AAC (0x0F, 0x11)
    /// - **Unsupported**: MPEG-2 video, AC-3, AC-4, and most other codecs
    ///
    /// Both video AND audio must use supported codecs for playback to work.
    ///
    /// - Returns: `true` if the stream is compatible with AVPlayer, `false` otherwise
    var isAVPlayerCompatible: Bool {
        let hasCompatibleVideo = videoStreamType == 0x1B || videoStreamType == 0x24
        let hasCompatibleAudio = audioStreamType == 0x0F || audioStreamType == 0x11
        return hasCompatibleVideo && hasCompatibleAudio
    }
    
    /// Returns a descriptive message explaining why the stream is incompatible with AVPlayer.
    ///
    /// **Responsibility:**
    /// Provides actionable feedback about codec compatibility issues.
    ///
    /// - Returns: A string describing the incompatibility, or `nil` if the stream is compatible
    var incompatibilityReason: String? {
        if isAVPlayerCompatible {
            return nil
        }
        
        var reasons: [String] = []
        
        // Check video codec
        if let videoType = videoStreamType {
            if videoType != 0x1B && videoType != 0x24 {
                let codecName = videoCodec ?? "Unknown"
                reasons.append("Video codec '\(codecName)' not supported (needs H.264 or H.265)")
            }
        }
        
        // Check audio codec
        if let audioType = audioStreamType {
            if audioType != 0x0F && audioType != 0x11 {
                let codecName = audioCodec ?? "Unknown"
                reasons.append("Audio codec '\(codecName)' not supported (needs AAC)")
            }
        }
        
        return reasons.isEmpty ? "Unknown compatibility issue" : reasons.joined(separator: "; ")
    }
}
