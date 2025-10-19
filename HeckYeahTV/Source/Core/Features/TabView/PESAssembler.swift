// PESAssembler.swift
// Heck Yeah TV
//
// Reassembles PES payloads for selected PIDs and extracts PTS for duration tracking.

import Foundation

final class PESAssembler {

    private let h264Parser: H264Parser
    private let onPTS: (_ pts90k: UInt64) -> Void

    // Buffer per PID
    private var buffers: [UInt16: Data] = [:]

    // Whether to run H.264 parsing
    private let expectsH264Provider: () -> Bool

    init(h264Parser: H264Parser, expectsH264Provider: @escaping () -> Bool, onPTS: @escaping (_ pts90k: UInt64) -> Void) {
        self.h264Parser = h264Parser
        self.expectsH264Provider = expectsH264Provider
        self.onPTS = onPTS
    }

    func consume(packet: TSPacket, videoPID: UInt16?, audioPID: UInt16?) {
        guard packet.hasPayload else { return }
        // Assemble for both selected PIDs so we can get PTS from either track.
        guard let vPID = videoPID ?? audioPID else { return }

        // Only accept packets for either the selected video or audio PID.
        if let vid = videoPID, packet.pid == vid {
            appendPayload(packet, pid: vid, isVideo: true)
        } else if let aud = audioPID, packet.pid == aud {
            appendPayload(packet, pid: aud, isVideo: false)
        }
    }

    private func appendPayload(_ packet: TSPacket, pid: UInt16, isVideo: Bool) {
        var payload = packet.payload
        if payload.isEmpty { return }

        if packet.payloadUnitStart {
            // New PES starts, flush previous
            if let existing = buffers[pid], !existing.isEmpty {
                processPES(existing, isVideo: isVideo)
            }
            buffers[pid] = Data()
        }
        buffers[pid, default: Data()].append(payload)
        // Optional: cap buffer size to avoid runaway
        if buffers[pid, default: Data()].count > 1_000_000 {
            processPES(buffers[pid] ?? Data(), isVideo: isVideo)
            buffers[pid] = Data()
        }
    }

    private func processPES(_ pes: Data, isVideo: Bool) {
        guard pes.count >= 9 else { return }
        // PES header: 0x000001, stream_id, PES_packet_length, flags....
        if !(pes[0] == 0x00 && pes[1] == 0x00 && pes[2] == 0x01) { return }

        let flags = pes[7]
        let headerDataLength = Int(pes[8])
        var idx = 9
        var pts: UInt64?
        if (flags & 0x80) != 0 {
            // PTS present (33 bits in 5 bytes)
            if idx + 5 <= pes.count {
                pts = decodePTS(Array(pes[idx ..< idx+5]))
            }
        }
        idx += headerDataLength
        if idx <= pes.count {
            let es = pes.suffix(from: idx)
            if let p = pts {
                onPTS(p)
                logConsole("PESAssembler: PTS=\(Double(p)/90000.0)")
            }
            // Only parse H.264 IDRs when the video stream is H.264 and this PES is video
            if isVideo, expectsH264Provider() {
                h264Parser.consume(es)
            }
        }
    }

    private func decodePTS(_ b: [UInt8]) -> UInt64 {
        // From ISO/IEC 13818-1
        let p = (UInt64(b[0] & 0x0E) << 29)
              | (UInt64(b[1]) << 22)
              | (UInt64(b[2] & 0xFE) << 14)
              | (UInt64(b[3]) << 7)
              | (UInt64(b[4] >> 1))
        return p
    }
}
