//
//  HDHomeRunProbe.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/24/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Network

/// Low-level HDHomeRun device discovery using UDP broadcast.
///
/// Based on the HDHomeRun discovery protocol specification:
/// - Protocol: UDP broadcast on port 65001
///   - macOS: Uses global broadcast (255.255.255.255)
///   - iOS/tvOS: Uses subnet-specific broadcast addresses for each network interface
/// - Packet format: Type (2 bytes) + Length (2 bytes) + Payload + CRC (4 bytes)
/// - All values are big-endian except CRC (little-endian)
///
/// References:
/// - https://github.com/Silicondust/libhdhomerun
/// - https://github.com/waypar/hdhomerun-protocol-docs
/// - https://www.silicondust.com/hdhomerun/hdhomerun_development.pdf
actor HDHomeRunProbe {

    // MARK: - Constants
    
    private static let discoveryPort: UInt16 = 65001
    private static let broadcastAddress = "255.255.255.255"
    private static let discoveryTimeout: TimeInterval = 3.0
    
    // HDHomeRun protocol constants
    private static let packetTypeDiscoveryRequest: UInt16 = 0x0002
    private static let packetTypeDiscoveryReply: UInt16 = 0x0003
    private static let tagDeviceType: UInt8 = 0x01 // HDHOMERUN_DEVICE_TYPE_TUNER (0x00000001)
    private static let tagDeviceID: UInt8 = 0x02
    private static let tagBaseURL: UInt8 = 0x2A
    
    static let HDHomeRunDeviceType_Tuner: Int = 1
    static let HDHomeRunDeviceType_Storage: Int = 5
    
    // MARK: - Types
    
    enum ProbeError: Error, LocalizedError {
        case socketCreationFailed(Error?)
        case broadcastSendFailed(Error)
        case noDevicesFound
        case timeout
        case invalidResponse(String)
        case networkUnavailable(Error)

        var errorDescription: String? {
            switch self {
                case .socketCreationFailed(let error):
                    if let error = error {
                        return "Failed to create UDP socket for device discovery: \(error.localizedDescription)"
                    }
                    return "Failed to create UDP socket for device discovery"
                case .broadcastSendFailed(let error):
                    return "Failed to send broadcast discovery packet: \(error.localizedDescription)"
                case .noDevicesFound:
                    return "No HDHomeRun devices found on the network"
                case .timeout:
                    return "Device discovery timed out"
                case .invalidResponse(let reason):
                    return "Received invalid response from device: \(reason)"
                case .networkUnavailable(let error):
                    return "Network is unavailable: \(error.localizedDescription)"
            }
        }
    }
    
    struct DiscoveredDevice: Hashable {
        let deviceID: String
        let deviceType: Int // 1 = Tuner, 5 = Storage
        let baseURL: String
        let ipAddress: String
    }
    
    // MARK: - Public API
    
    /// Discovers HDHomeRun devices on the local network.
    ///
    /// Sends a discovery packet on UDP port 65001 and listens for responses from HDHomeRun devices.
    /// On macOS, uses global broadcast (255.255.255.255). On iOS/tvOS, sends to subnet-specific
    /// broadcast addresses for each active network interface.
    ///
    /// - Parameter targetIP: Optional specific IP address to probe via unicast instead of broadcast
    /// - Returns: An array of discovered devices (duplicates are automatically filtered)
    /// - Throws: `ProbeError` if discovery fails or no devices are found
    func discoverDevices(targetIP: String? = nil) async throws -> [DiscoveredDevice] {
        let devices = try await self.performDiscovery(targetIP: targetIP)
        return devices
    }
    
    // MARK: - Private Implementation
    
    private func performDiscovery(targetIP: String? = nil) async throws -> [DiscoveredDevice] {
        
        // Create UDP socket
        let socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket >= 0 else {
            throw ProbeError.socketCreationFailed(nil)
        }
        
        defer {
            close(socket)
        }
        
        // Enable broadcast
        var broadcastEnable: Int32 = 1
        let broadcastResult = setsockopt(socket, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, socklen_t(MemoryLayout<Int32>.size))
        guard broadcastResult >= 0 else {
            throw ProbeError.socketCreationFailed(nil)
        }
        
        // Bind to any address on any port (OS will assign a port)
        var bindAddr = sockaddr_in()
        bindAddr.sin_family = sa_family_t(AF_INET)
        bindAddr.sin_port = 0  // Let OS choose port
        bindAddr.sin_addr.s_addr = INADDR_ANY.bigEndian
        
        let bindResult = withUnsafePointer(to: &bindAddr) { addrPtr in
            addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(socket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard bindResult >= 0 else {
            throw ProbeError.socketCreationFailed(nil)
        }
        
        // Set socket timeout
        var timeout = timeval(tv_sec: 1, tv_usec: 0)
        _ = setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        
        // Send discovery broadcast or unicast
        let discoveryPacket = createDiscoveryPacket()
        
        if let targetIP = targetIP {
            try sendUnicast(socket: socket, data: discoveryPacket, targetIP: targetIP)
        } else {
            try sendBroadcast(socket: socket, data: discoveryPacket)
        }
        
        // Listen for responses
        let devices = try receiveResponses(socket: socket)
        
        guard !devices.isEmpty else {
            throw ProbeError.noDevicesFound
        }
        
        return devices
    }
    
    private func createDiscoveryPacket() -> Data {
        var payload = Data()
        
        // Device type tag - HDHOMERUN_DEVICE_TYPE_TUNER (0x00000001)
        payload.append(Self.tagDeviceType)  // Tag: 0x01
        payload.append(0x04)  // Length: 4 bytes
        payload.append(contentsOf: withUnsafeBytes(of: UInt32(0x00000001).bigEndian) { Array($0) })  // Tuner type
        
        // Packet header
        var packet = Data()
        packet.append(contentsOf: withUnsafeBytes(of: Self.packetTypeDiscoveryRequest.bigEndian) { Array($0) })  // Type
        packet.append(contentsOf: withUnsafeBytes(of: UInt16(payload.count).bigEndian) { Array($0) })  // Length
        packet.append(payload)  // Payload
        
        // Calculate and append CRC32 (little-endian)
        let crc = calculateCRC32(data: packet)
        packet.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Array($0) })
        
        return packet
    }
    
    private func sendBroadcast(socket: Int32, data: Data) throws {
#if os(iOS) || os(tvOS)
        // On iOS/tvOS, send to all available network interfaces
        let broadcastAddresses = getAllSubnetBroadcastAddresses()
        
        if broadcastAddresses.isEmpty {
            try sendToBroadcastAddress(socket: socket, data: data, address: Self.broadcastAddress)
        } else {
            var sentCount = 0
            for (interface, address) in broadcastAddresses {
                do {
                    try sendToBroadcastAddress(socket: socket, data: data, address: address)
                    sentCount += 1
                } catch {
                    logError("Failed on \(interface): \(address) - \(error)")
                }
            }
            
            guard sentCount > 0 else {
                logError("Sending broadcast failed, see previous log messages.")
                throw ProbeError.broadcastSendFailed(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)))
            }
        }
#else
        // macOS: use global broadcast
        try sendToBroadcastAddress(socket: socket, data: data, address: Self.broadcastAddress)
#endif
    }
    
    private func sendToBroadcastAddress(socket: Int32, data: Data, address: String) throws {
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = Self.discoveryPort.bigEndian
        addr.sin_addr.s_addr = inet_addr(address)
        
        let sent = data.withUnsafeBytes { buffer in
            withUnsafePointer(to: addr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    sendto(socket, buffer.baseAddress, data.count, 0, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
        
        guard sent >= 0 else {
            throw ProbeError.broadcastSendFailed(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)))
        }
    }
    
    /// Gets all subnet broadcast addresses for all available network interfaces (iOS/tvOS only).
    ///
    /// Enumerates IPv4 network interfaces (excluding loopback) and returns their broadcast addresses.
    /// This is necessary on iOS/tvOS because global broadcast (255.255.255.255) is restricted.
    ///
    /// - Returns: Array of (interface name, broadcast address) tuples
    private func getAllSubnetBroadcastAddresses() -> [(String, String)] {
        var results: [(String, String)] = []
        
#if os(iOS) || os(tvOS)
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return results }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            // Only look at IPv4 addresses
            guard addrFamily == UInt8(AF_INET) else { continue }
            
            // Skip loopback
            let name = String(cString: interface.ifa_name)
            guard name != "lo0" else { continue }
            
            // Get broadcast address if available
            if let broadAddr = interface.ifa_dstaddr {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(broadAddr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, 0, NI_NUMERICHOST) == 0 {
                    let address = String(cString: hostname)
                    results.append((name, address))
                }
            }
        }
#endif
        
        return results
    }
    
    private func sendUnicast(socket: Int32, data: Data, targetIP: String) throws {
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = Self.discoveryPort.bigEndian
        addr.sin_addr.s_addr = inet_addr(targetIP)
        
        let sent = data.withUnsafeBytes { buffer in
            withUnsafePointer(to: addr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    sendto(socket, buffer.baseAddress, data.count, 0, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
        
        guard sent >= 0 else {
            logError("Unicast send failed: errno=\(errno), sent=\(sent)")
            throw ProbeError.broadcastSendFailed(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)))
        }
    }
    
    private func receiveResponses(socket: Int32) throws -> [DiscoveredDevice] {
        var devices: [DiscoveredDevice] = []
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < Self.discoveryTimeout {
            do {
                if let device = try receiveOneResponse(socket: socket) {
                    devices.append(device)
                }
            } catch {
                logError("Receive loop ended: \(error)")
                break
            }
        }
        
        return devices
    }
    
    private func receiveOneResponse(socket: Int32) throws -> DiscoveredDevice? {
        var buffer = Data(count: 4096)
        var addr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        
        let bufferSize = buffer.count
        let received = buffer.withUnsafeMutableBytes { bufferPtr in
            withUnsafeMutablePointer(to: &addr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    recvfrom(socket, bufferPtr.baseAddress, bufferSize, 0, sockaddrPtr, &addrLen)
                }
            }
        }
        
        guard received > 0 else {
            if errno == EAGAIN || errno == EWOULDBLOCK {
                throw ProbeError.timeout
            }
            throw ProbeError.invalidResponse("Failed to receive data")
        }
        
        let responseData = buffer.prefix(received)
        guard responseData.count > 8 else {
            throw ProbeError.invalidResponse("Packet too small")
        }
        
        // Extract IP address from sockaddr
        let ipAddress = String(cString: inet_ntoa(addr.sin_addr))
        
        return try parseDiscoveryResponse(data: responseData, ipAddress: ipAddress)
    }
    
    nonisolated private func parseDiscoveryResponse(data: Data, ipAddress: String) throws -> DiscoveredDevice {
        guard data.count >= 8 else {
            throw ProbeError.invalidResponse("Packet too small: \(data.count) bytes")
        }
        
        // Verify packet type (should be 0x0003 for discovery reply) - read as big-endian
        let packetType = UInt16(data[0]) << 8 | UInt16(data[1])
        guard packetType == Self.packetTypeDiscoveryReply else {
            throw ProbeError.invalidResponse("Invalid packet type: \(packetType)")
        }
        
        // Get payload length - read as big-endian
        let payloadLength = UInt16(data[2]) << 8 | UInt16(data[3])
        
        // Parse TLV payload
        var deviceID: String?
        var deviceType: Int?
        var baseURL: String?
        
        var offset = 4  // Skip type and length fields
        let payloadEnd = Int(payloadLength) + 4
        
        while offset < min(payloadEnd, data.count - 4) {  // -4 for CRC
            let tag = data[offset]
            offset += 1
            
            guard offset < data.count else { break }
            var length = Int(data[offset])
            offset += 1
            
            // Handle 2-byte length encoding (if length > 127)
            if length > 127 {
                length = ((length & 0x7F) << 8) | Int(data[offset])
                offset += 1
            }
            
            guard offset + length <= data.count else { break }
            let value = data[offset..<(offset + length)]
            offset += length
            
            switch tag {
                case Self.tagDeviceID:
                    // Read 4 bytes as big-endian UInt32 and format as hex string
                    if value.count >= 4 {
                        let id = UInt32(value[value.startIndex]) << 24 |
                        UInt32(value[value.startIndex + 1]) << 16 |
                        UInt32(value[value.startIndex + 2]) << 8 |
                        UInt32(value[value.startIndex + 3])
                        deviceID = String(format: "%08X", id)
                    }
                case Self.tagDeviceType:
                    // Device type is sent as a 4-byte big-endian integer
                    if value.count >= 4 {
                        let type = Int(UInt32(value[value.startIndex]) << 24 |
                                       UInt32(value[value.startIndex + 1]) << 16 |
                                       UInt32(value[value.startIndex + 2]) << 8 |
                                       UInt32(value[value.startIndex + 3]))
                        deviceType = type
                    }
                case Self.tagBaseURL:
                    baseURL = String(data: value, encoding: .ascii)
                default:
                    break
            }
        }
        
        guard let deviceID = deviceID,
              let deviceType = deviceType,
              let baseURL = baseURL else {
            throw ProbeError.invalidResponse("Missing required fields in response")
        }
        
        return DiscoveredDevice(
            deviceID: deviceID,
            deviceType: deviceType,
            baseURL: baseURL,
            ipAddress: ipAddress
        )
    }
    
    nonisolated private func calculateCRC32(data: Data) -> UInt32 {
        // HDHomeRun CRC32 calculation - matches official libhdhomerun implementation
        var crc: UInt32 = 0xFFFFFFFF
        
        for byte in data {
            let x = UInt8(crc & 0xFF) ^ byte
            crc >>= 8
            if (x & 0x01) != 0 { crc ^= 0x77073096 }
            if (x & 0x02) != 0 { crc ^= 0xEE0E612C }
            if (x & 0x04) != 0 { crc ^= 0x076DC419 }
            if (x & 0x08) != 0 { crc ^= 0x0EDB8832 }
            if (x & 0x10) != 0 { crc ^= 0x1DB71064 }
            if (x & 0x20) != 0 { crc ^= 0x3B6E20C8 }
            if (x & 0x40) != 0 { crc ^= 0x76DC4190 }
            if (x & 0x80) != 0 { crc ^= 0xEDB88320 }
        }
        
        return crc ^ 0xFFFFFFFF
    }
}
