// ProgramMap.swift
// Heck Yeah TV
//
// Robust PAT/PMT parsing with PSI reassembly, pointer_field handling,
// stuffing skip, continuity counter checks, and strong bounds validation.

import Foundation

final class ProgramMap {

    private var pmtPID: UInt16?
    private(set) var videoPID: UInt16?
    private(set) var audioPID: UInt16?

    private var patBuffer = Data()
    private var pmtBuffer = Data()

    // Continuity counters to detect packet loss and reset buffers
    private var patContinuity: UInt8?
    private var pmtContinuity: UInt8?

    // Resync guardrails
    private var patResyncDrops = 0
    private var pmtResyncDrops = 0
    private let maxResyncDrops = 32
    private let maxPSIBufferBytes = 8192

    // Now includes isH264 to tell downstream whether the selected video stream is H.264 or not.
    private let onProgramReady: (_ videoPID: UInt16, _ audioPID: UInt16?, _ isH264: Bool) -> Void

    init(onProgramReady: @escaping (_ videoPID: UInt16, _ audioPID: UInt16?, _ isH264: Bool) -> Void) {
        self.onProgramReady = onProgramReady
    }

    func consume(packet: TSPacket) {
        guard packet.hasPayload else { return }

        if packet.pid == 0x0000 {
            // PAT
            if continuityBroken(last: &patContinuity, new: packet.continuityCounter, hasPayload: packet.hasPayload) {
                logWarning("ProgramMap: PAT continuity break; resetting PAT buffer.")
                patBuffer.removeAll(keepingCapacity: true)
                patResyncDrops = 0
            }
            appendSection(payload: packet.payload,
                          payloadUnitStart: packet.payloadUnitStart,
                          to: &patBuffer,
                          expectedTableId: 0x00,
                          minFixedHeader: 8,
                          isPMT: false) { section in
                parsePAT(section)
            }
        } else if let pmt = pmtPID, packet.pid == pmt {
            if continuityBroken(last: &pmtContinuity, new: packet.continuityCounter, hasPayload: packet.hasPayload) {
                logWarning("ProgramMap: PMT continuity break; resetting PMT buffer.")
                pmtBuffer.removeAll(keepingCapacity: true)
                pmtResyncDrops = 0
            }
            appendSection(payload: packet.payload,
                          payloadUnitStart: packet.payloadUnitStart,
                          to: &pmtBuffer,
                          expectedTableId: 0x02,
                          minFixedHeader: 12,
                          isPMT: true) { section in
                parsePMT(section)
            }
        }
    }

    // MARK: - Continuity

    private func continuityBroken(last: inout UInt8?, new: UInt8, hasPayload: Bool) -> Bool {
        // Only meaningful when payload present (afc includes payload)
        guard hasPayload else { last = new; return false }
        if let l = last {
            let expected = (l &+ 1) & 0x0F
            last = new
            return new != expected
        } else {
            last = new
            return false
        }
    }

    // MARK: - PSI section reassembly

    private func appendSection(payload: Data,
                               payloadUnitStart: Bool,
                               to buffer: inout Data,
                               expectedTableId: UInt8,
                               minFixedHeader: Int,
                               isPMT: Bool,
                               complete: (Data) -> Void) {
        guard !payload.isEmpty else { return }
        var data = payload

        if payloadUnitStart {
            // Reset buffer and apply pointer_field
            guard data.count >= 1 else {
                buffer.removeAll(keepingCapacity: true)
                if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
                return
            }
            let pointerField = Int(data[data.startIndex])
            // Ensure we can advance by 1 + pointerField
            let needed = 1 + pointerField
            guard data.count >= needed else {
                buffer.removeAll(keepingCapacity: true)
                if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
                return
            }
            data = data.advanced(by: needed)
            buffer.removeAll(keepingCapacity: true)
            if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
        }

        // Append bytes
        if !data.isEmpty {
            buffer.append(data)
        }

        // Cap runaway growth on noisy streams
        if buffer.count > maxPSIBufferBytes {
            logWarning("ProgramMap: PSI buffer exceeded \(maxPSIBufferBytes) bytes; resetting.")
            buffer.removeAll(keepingCapacity: true)
            if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
            return
        }

        // Try to extract complete sections
        var iterationsWithoutProgress = 0
        let maxNoProgressIterations = 8

        parsingLoop: while true {
            let beforeCount = buffer.count

            // Remove leading stuffing (0xFF), if any
            if let firstByte = buffer.first, firstByte == 0xFF {
                var removeCount = 0
                for b in buffer {
                    if b == 0xFF { removeCount += 1 } else { break }
                }
                if removeCount > 0 {
                    buffer.removeFirst(removeCount)
                    if buffer.isEmpty { break }
                    iterationsWithoutProgress = 0
                    continue
                }
            }

            // Ensure we have at least 3 bytes for table_id + section_length
            guard buffer.count >= 3 else { break }

            // Snapshot bytes via startIndex-based indexing
            let i0 = buffer.startIndex
            let i1 = buffer.index(i0, offsetBy: 1)
            let i2 = buffer.index(i0, offsetBy: 2)
            let b0 = buffer[i0]
            let b1 = buffer[i1]
            let b2 = buffer[i2]

            if b0 != expectedTableId {
                // If not expected table, try to resync by dropping one byte
                if isPMT {
                    pmtResyncDrops += 1
                    if pmtResyncDrops > maxResyncDrops {
                        logWarning("ProgramMap: PMT resync exceeded \(maxResyncDrops) drops; resetting buffer.")
                        buffer.removeAll(keepingCapacity: true)
                        pmtResyncDrops = 0
                        break
                    }
                } else {
                    patResyncDrops += 1
                    if patResyncDrops > maxResyncDrops {
                        logWarning("ProgramMap: PAT resync exceeded \(maxResyncDrops) drops; resetting buffer.")
                        buffer.removeAll(keepingCapacity: true)
                        patResyncDrops = 0
                        break
                    }
                }
                logWarning("ProgramMap: unexpected table_id=0x\(String(format: "%02X", b0)); expected 0x\(String(format: "%02X", expectedTableId)). Resync by byte.")
                buffer.removeFirst(1)
                if buffer.isEmpty { break }
                iterationsWithoutProgress = 0
                continue
            }

            // Safe to read section_length now from b1/b2
            let sectionLength = Int(((b1 & 0x0F) << 8) | b2)

            // Spec says <= 1021
            if sectionLength <= 0 || sectionLength > 1021 {
                logError("ProgramMap: invalid section_length=\(sectionLength). Dropping buffer and waiting for next start.")
                buffer.removeAll(keepingCapacity: true)
                if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
                break
            }

            let total = 3 + sectionLength
            guard total > 0, total <= 4096 else {
                buffer.removeAll(keepingCapacity: true)
                if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
                break
            }

            // Require fixed header length (8 for PAT, 12 for PMT)
            if total < minFixedHeader {
                logWarning("ProgramMap: section too small (total=\(total), minFixedHeader=\(minFixedHeader)). Reset buffer.")
                buffer.removeAll(keepingCapacity: true)
                if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
                break
            }

            guard buffer.count >= total else {
                // Wait for more bytes
                break
            }

            // Slice section using indices (avoid assuming zero startIndex)
            let end = buffer.index(i0, offsetBy: total)
            let sectionSlice = buffer[i0..<end]
            complete(Data(sectionSlice))
            buffer.removeFirst(total)

            // Successful parse resets resync drop counters and progress counter
            if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
            iterationsWithoutProgress = 0

            if buffer.isEmpty { break }

            if buffer.count == beforeCount {
                iterationsWithoutProgress += 1
                if iterationsWithoutProgress >= maxNoProgressIterations {
                    logWarning("ProgramMap: No progress in PSI parsing for \(maxNoProgressIterations) iterations; resetting buffer.")
                    buffer.removeAll(keepingCapacity: true)
                    if isPMT { pmtResyncDrops = 0 } else { patResyncDrops = 0 }
                    break
                }
            }
        }
    }

    // MARK: - PAT/PMT parsing

    private func parsePAT(_ section: Data) {
        // table_id (1), section_length (2), transport_stream_id (2),
        // version/cni/section_number/last_section_number (5) → total 8 bytes header
        guard section.count >= 8 else { return }
        var idx = 8
        // Entries of 4 bytes until CRC (last 4 bytes)
        while idx + 4 <= section.count - 4 {
            let programNumber = (UInt16(section[section.index(section.startIndex, offsetBy: idx)]) << 8) |
                                UInt16(section[section.index(section.startIndex, offsetBy: idx + 1)])
            let pid = UInt16(section[section.index(section.startIndex, offsetBy: idx + 2)] & 0x1F) << 8 |
                      UInt16(section[section.index(section.startIndex, offsetBy: idx + 3)])
            idx += 4
            if programNumber != 0 {
                pmtPID = pid
                logConsole("ProgramMap: PAT found PMT PID=\(pid)")
                break
            }
        }
    }

    private func parsePMT(_ section: Data) {
        // table_id (1), section_length (2), program_number (2), version/etc (2),
        // PCR_PID (2), program_info_length (2) => 12 bytes
        guard section.count >= 12 else { return }
        var idx = 12

        // Skip program descriptors if any
        let s0 = section.startIndex
        let i10 = section.index(s0, offsetBy: 10)
        let i11 = section.index(s0, offsetBy: 11)
        let progInfoLen = Int(((section[i10] & 0x0F) << 8) | section[i11])
        guard section.count >= 12 + progInfoLen + 4 else { return }
        idx += progInfoLen

        var vPID: UInt16?
        var aPID: UInt16?
        var videoIsH264: Bool?

        while idx + 5 <= section.count - 4 {
            let i = section.index(s0, offsetBy: idx)
            let i1 = section.index(i, offsetBy: 1)
            let i2 = section.index(i, offsetBy: 2)
            let i3 = section.index(i, offsetBy: 3)
            let i4 = section.index(i, offsetBy: 4)

            let streamType = section[i]
            let elementaryPID = UInt16(section[i1] & 0x1F) << 8 | UInt16(section[i2])
            let esInfoLength = Int(((section[i3] & 0x0F) << 8) | section[i4])

            let nextIdx = idx + 5 + esInfoLength
            if nextIdx > section.count - 4 {
                logWarning("ProgramMap: PMT ES info overruns section (idx=\(idx), esInfoLength=\(esInfoLength), section.count=\(section.count)). Stopping ES loop.")
                break
            }

            logConsole("ProgramMap: PMT stream_type=0x\(String(format: "%02X", streamType)) PID=\(elementaryPID)")

            // Video: accept H.264 (0x1B) and MPEG-2 Video (0x02)
            if (streamType == 0x1B || streamType == 0x02), vPID == nil {
                vPID = elementaryPID
                videoIsH264 = (streamType == 0x1B)
            }

            // Audio: accept AAC (0x0F), MPEG audio (0x03), and AC-3 (0x81 commonly)
            if (streamType == 0x0F || streamType == 0x03 || streamType == 0x81), aPID == nil {
                aPID = elementaryPID
            }

            idx = nextIdx
        }

        if let v = vPID {
            videoPID = v
            audioPID = aPID
            let isH264 = (videoIsH264 == true)
            logConsole("ProgramMap: Selected video PID=\(v) audio PID=\(aPID ?? 0) isH264=\(isH264)")
            onProgramReady(v, aPID, isH264)
        } else {
            logWarning("ProgramMap: No supported video stream found in PMT yet.")
        }
    }
}
