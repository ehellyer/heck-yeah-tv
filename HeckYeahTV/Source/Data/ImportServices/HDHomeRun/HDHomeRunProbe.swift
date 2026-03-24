//
//  HDHomeRunProbe.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/24/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Network

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Low-level HDHomeRun device discovery using UDP broadcast.
///
/// Based on the HDHomeRun discovery protocol specification:
/// - Protocol: UDP broadcast on port 65001 to 255.255.255.255
/// - Packet format: Type (2 bytes) + Length (2 bytes) + Payload + CRC (4 bytes)
/// - All values are big-endian except CRC (little-endian)
///
/// **Important**: This implementation uses BSD sockets and UDP broadcast/unicast.
/// It will NOT work in the iOS/tvOS Simulator due to network isolation limitations.
/// Testing must be done on real hardware (Apple TV device).
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
    private static let tagDeviceType: UInt8 = 0x01
    private static let tagDeviceID: UInt8 = 0x02
    private static let tagBaseURL: UInt8 = 0x2A
    
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
    
    struct DiscoveredDevice {
        let deviceID: String
        let deviceType: String
        let baseURL: String
        let ipAddress: String
    }
    
    // MARK: - Public API
    
    /// Discovers HDHomeRun devices on the local network.
    ///
    /// This function broadcasts a discovery packet on UDP port 65001 and listens for responses
    /// from HDHomeRun devices.
    ///
    /// **Note**: This will NOT work in the iOS/tvOS Simulator due to network isolation.
    /// Must be tested on real Apple TV hardware.
    ///
    /// - Returns: An array of discovered devices
    /// - Throws: `ProbeError` if discovery fails or no devices are found
    func discoverDevices() async throws -> [DiscoveredDevice] {
        let devices = try await self.performDiscovery()
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
        guard setsockopt(socket, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, socklen_t(MemoryLayout<Int32>.size)) >= 0 else {
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
        setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        
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
        var packet = Data()
        
        // Packet type (discovery request) - big-endian
        packet.append(contentsOf: withUnsafeBytes(of: Self.packetTypeDiscoveryRequest.bigEndian) { Array($0) })
        
        // Payload length - big-endian
        let payloadLength: UInt16 = 8  // Device ID tag (1) + length (1) + value (4) + device type tag (1) + length (1)
        packet.append(contentsOf: withUnsafeBytes(of: payloadLength.bigEndian) { Array($0) })
        
        // Payload: Device ID wildcard (tag + length + value)
        packet.append(Self.tagDeviceID)  // Tag: 0x02
        packet.append(0x04)  // Length: 4 bytes
        packet.append(contentsOf: withUnsafeBytes(of: UInt32(0xFFFFFFFF).bigEndian) { Array($0) })  // Wildcard device ID
        
        // Device type wildcard
        packet.append(Self.tagDeviceType)  // Tag: 0x01
        packet.append(0x01)  // Length: 1 byte
        packet.append(0xFF)  // Value: wildcard
        packet.append(0x00)  // Padding for 4-byte alignment
        
        // Calculate and append CRC32 (little-endian)
        let crc = calculateCRC32(data: packet)
        packet.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Array($0) })
        
        return packet
    }
    
    private func sendBroadcast(socket: Int32, data: Data) throws {
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = Self.discoveryPort.bigEndian
        addr.sin_addr.s_addr = inet_addr(Self.broadcastAddress)
        
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
                // Timeout or no more responses
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
        // Verify packet type (should be discovery reply)
        let packetType = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt16.self) }.bigEndian
        guard packetType == Self.packetTypeDiscoveryReply else {
            throw ProbeError.invalidResponse("Invalid packet type: \(packetType)")
        }
        
        // Get payload length
        let payloadLength = data.withUnsafeBytes { $0.load(fromByteOffset: 2, as: UInt16.self) }.bigEndian
        
        // Parse TLV payload
        var deviceID: String?
        var deviceType: String?
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
                deviceID = String(format: "%08X", value.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian)
            case Self.tagDeviceType:
                deviceType = String(data: value, encoding: .ascii) ?? "unknown"
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
        // Ethernet-style CRC32 (polynomial 0x04C11DB7)
        var crc: UInt32 = 0xFFFFFFFF
        
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                if (crc & 1) != 0 {
                    crc = (crc >> 1) ^ 0xEDB88320
                } else {
                    crc = crc >> 1
                }
            }
        }
        
        return ~crc
    }
}
