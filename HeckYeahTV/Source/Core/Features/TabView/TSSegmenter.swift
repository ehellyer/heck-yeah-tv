// TSSegmenter.swift
// Heck Yeah TV
//
// Buffers TS packets for selected PIDs, cuts segments on keyframes when target duration reached,
// writes segment files, and updates the playlist.

import Foundation

final class TSSegmenter {

    private let workDir: URL
    private let playlist: LivePlaylist
    private let targetDuration: Double

    private(set) var videoPID: UInt16?
    private(set) var audioPID: UInt16?
    private(set) var expectsH264: Bool = true

    private var currentSegmentPackets = Data()
    private var currentStartPTS: UInt64?
    private var lastPTS: UInt64?
    private var pendingKeyframe = false
    private var segmentIndex: Int = 0
    private var isClosed = false

    init(workDir: URL, playlist: LivePlaylist, targetDuration: Double) {
        self.workDir = workDir
        self.playlist = playlist
        self.targetDuration = targetDuration
    }

    func selectPIDs(video: UInt16, audio: UInt16?, isH264: Bool) {
        self.videoPID = video
        self.audioPID = audio
        self.expectsH264 = isH264
        logConsole("Program ready. Video PID=\(video) Audio PID=\(audio ?? 0) isH264=\(isH264)")
    }

    func updatePTS(_ pts90k: UInt64) {
        if currentStartPTS == nil { currentStartPTS = pts90k }
        lastPTS = pts90k
    }

    func markKeyframe() {
        pendingKeyframe = true
    }

    func consume(packet: TSPacket) {
        guard !isClosed else { return }
        currentSegmentPackets.append(serialize(packet))
        tryRotateIfNeeded()
    }

    private func tryRotateIfNeeded() {
        guard let start = currentStartPTS, let last = lastPTS else { return }
        let elapsed = Double(last &- start) / 90000.0
        if elapsed >= targetDuration {
            logConsole("Segmenter: rotate, elapsed=\(elapsed)")
            finalizeCurrentSegment(duration: elapsed)
            pendingKeyframe = false
            currentStartPTS = last
            currentSegmentPackets = Data()
        }
    }

    private func finalizeCurrentSegment(duration: Double) {
        segmentIndex += 1
        let name = String(format: "segment%05d.ts", segmentIndex)
        let url = workDir.appendingPathComponent(name)
        do {
            try currentSegmentPackets.write(to: url, options: .atomic)
            logConsole("Segmenter: wrote \(name) duration=\(String(format: "%.3f", duration))s bytes=\(currentSegmentPackets.count)")
            playlist.append(segmentName: name, duration: duration)
        } catch {
            logError("Failed to write segment: \(error)")
        }
    }

    func finishAndClose() {
        isClosed = true
        if let start = currentStartPTS, let last = lastPTS {
            let elapsed = Double(last &- start) / 90000.0
            if elapsed > 0.5 {
                finalizeCurrentSegment(duration: elapsed)
            }
        }
    }

    private func serialize(_ packet: TSPacket) -> Data {
        return packet.raw188
    }
}
