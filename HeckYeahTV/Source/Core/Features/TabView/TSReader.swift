// TSReader.swift
// Heck Yeah TV
//
// Reads an MPEG-TS stream over HTTP and emits parsed 188-byte packets.

import Foundation

struct TSPacket {
    let pid: UInt16
    let payloadUnitStart: Bool
    let hasAdaptation: Bool
    let hasPayload: Bool
    let continuityCounter: UInt8
    let payload: Data
    let raw188: Data
}

final class TSReader {
    private let sourceURL: URL
    private let onPacket: (TSPacket) -> Void
    private let onError: (Error) -> Void

    private var buffer = Data()
    private let queue = DispatchQueue(label: "TSReader.queue")

    private var isRunning = false
    private var isEmitting = false // re-entrancy guard (access only on queue)

    init(sourceURL: URL, onPacket: @escaping (TSPacket) -> Void, onError: @escaping (Error) -> Void) {
        self.sourceURL = sourceURL
        self.onPacket = onPacket
        self.onError = onError
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        Task.detached { [weak self] in
            await self?.readLoop()
        }
    }

    func stop() {
        isRunning = false
    }

    // Finds a sync byte (0x47) such that there is another sync exactly 188 bytes later.
    private func syncIndex(in data: Data, start: Int) -> Int? {
        let packetSize = 188
        var i = start
        while i + packetSize < data.count {
            // Use index-based access
            let base = data.startIndex
            let idx = data.index(base, offsetBy: i)
            if data[idx] == 0x47 {
                let nextI = i + packetSize
                if nextI < data.count {
                    let nextIdx = data.index(base, offsetBy: nextI)
                    if data[nextIdx] == 0x47 {
                        return i
                    }
                }
            }
            i += 1
        }
        return nil
    }

    // Parse a single 188-byte packet starting at byte offset using index-based access only.
    private func parsePacket(_ data: Data, offset: Int) -> TSPacket? {
        let packetSize = 188
        guard offset + packetSize <= data.count else { return nil }

        let base = data.startIndex
        let o0 = data.index(base, offsetBy: offset)
        let o1 = data.index(o0, offsetBy: 1)
        let o2 = data.index(o0, offsetBy: 2)
        let o3 = data.index(o0, offsetBy: 3)
        let end = data.index(o0, offsetBy: packetSize)

        // raw slice
        let rawSlice = data[o0..<end]

        // header bytes
        let b0 = data[o1]
        let b1 = data[o2]
        let b2 = data[o3]

        let payloadUnitStart = (b0 & 0x40) != 0
        let pid = UInt16(b0 & 0x1F) << 8 | UInt16(b1)
        let afc = (b2 & 0x30) >> 4
        let hasAdaptation = (afc == 2 || afc == 3)
        let hasPayload = (afc == 1 || afc == 3)
        let continuity = b2 & 0x0F

        var idxInt = offset + 4
        let endInt = offset + packetSize

        if hasAdaptation {
            guard idxInt < endInt else { return nil }
            let idx = data.index(base, offsetBy: idxInt)
            let len = Int(data[idx])
            let after = idxInt + 1 + len
            // If invalid adaptation length, return empty-payload packet to advance safely
            guard after <= endInt else {
                return TSPacket(pid: pid,
                                payloadUnitStart: payloadUnitStart,
                                hasAdaptation: true,
                                hasPayload: false,
                                continuityCounter: continuity,
                                payload: Data(),
                                raw188: Data(rawSlice))
            }
            idxInt = after
        }

        let payload: Data
        if hasPayload, idxInt < endInt {
            let pStart = data.index(base, offsetBy: idxInt)
            let pEnd = data.index(base, offsetBy: endInt)
            payload = Data(data[pStart..<pEnd])
        } else {
            payload = Data()
        }

        return TSPacket(pid: pid,
                        payloadUnitStart: payloadUnitStart,
                        hasAdaptation: hasAdaptation,
                        hasPayload: hasPayload,
                        continuityCounter: continuity,
                        payload: payload,
                        raw188: Data(rawSlice))
    }

    private func emitPacketsFromBuffer() {
        // Re-entrancy guard: if already emitting on this queue, just return; the current emitter will handle pending bytes.
        if isEmitting { return }
        isEmitting = true
        defer { isEmitting = false }

        let packetSize = 188
        var start = 0
        var out = [TSPacket]()

        // Force a contiguous snapshot for safe parsing and use index-based access only.
        let snapshot = Data(buffer)

        while true {
            // Need at least one full packet ahead of 'start'
            guard snapshot.count - start >= packetSize else { break }

            // Ensure sync at 'start' using indices
            do {
                let base = snapshot.startIndex
                let sIdx = snapshot.index(base, offsetBy: start)
                if snapshot[sIdx] != 0x47 {
                    if let s = syncIndex(in: snapshot, start: start) {
                        start = s
                    } else {
                        // Keep only tail bytes that might form the next header in the real buffer
                        if buffer.count > packetSize - 1 {
                            buffer = buffer.suffix(packetSize - 1)
                        }
                        // Deliver any accumulated packets before returning
                        if !out.isEmpty {
                            let packets = out
                            out.removeAll(keepingCapacity: true)
                            for p in packets { onPacket(p) }
                        }
                        return
                    }
                    // After resync, ensure we still have a full packet
                    guard snapshot.count - start >= packetSize else { break }
                }
            }

            // Parse packet from the snapshot
            guard let pkt = parsePacket(snapshot, offset: start) else {
                break
            }
            out.append(pkt)

            // Advance by exactly one packet
            start += packetSize
        }

        // Remove consumed bytes from the real buffer based on how much we parsed from the snapshot
        if start > 0 {
            let toRemove = min(start, buffer.count)
            buffer.removeFirst(toRemove)
        }

        // Deliver packets after buffer mutation to avoid re-entrancy issues
        if !out.isEmpty {
            let packets = out
            out.removeAll(keepingCapacity: true)
            for p in packets { onPacket(p) }
        }
    }

    private func append(_ data: Data) {
        buffer.append(data)
        emitPacketsFromBuffer()
    }

    private func readLoop() async {
        do {
            let (bytes, _) = try await URLSession.shared.bytes(from: sourceURL)
            var local = [UInt8]()
            local.reserveCapacity(4096)

            for try await byte in bytes {
                if !isRunning { break }
                local.append(byte)
                if local.count >= 2048 {
                    let chunk = Data(local)
                    local.removeAll(keepingCapacity: true)
                    queue.async { [weak self] in
                        self?.append(chunk)
                    }
                }
            }
            // Flush any remaining
            if !local.isEmpty {
                let chunk = Data(local)
                queue.async { [weak self] in
                    self?.append(chunk)
                }
            }
        } catch {
            onError(error)
        }
    }
}
