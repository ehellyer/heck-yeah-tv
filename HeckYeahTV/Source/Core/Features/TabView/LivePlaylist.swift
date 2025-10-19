// LivePlaylist.swift
// Heck Yeah TV
//
// Maintains a rolling HLS playlist and writes index.m3u8.

import Foundation

final class LivePlaylist {

    struct Entry {
        let name: String
        let duration: Double
    }

    private let workDir: URL
    private let targetDuration: Double
    private let windowSize: Int
    private let segmentNamePattern: String

    private var entries: [Entry] = []
    private var mediaSequence: Int = 0

    init(workDir: URL, targetDuration: Double, windowSize: Int, segmentNamePattern: String) {
        self.workDir = workDir
        self.targetDuration = targetDuration
        self.windowSize = windowSize
        self.segmentNamePattern = segmentNamePattern
    }

    func append(segmentName: String, duration: Double) {
        entries.append(Entry(name: segmentName, duration: duration))
        if entries.count > windowSize {
            entries.removeFirst(entries.count - windowSize)
            mediaSequence += 1
            // delete old files
            let fm = FileManager.default
            let prefix = "segment"
            let oldIndex = mediaSequence - 1
            let oldName = String(format: "\(prefix)%05d.ts", oldIndex)
            let oldURL = workDir.appendingPathComponent(oldName)
            try? fm.removeItem(at: oldURL)
        }
        writePlaylist()
    }

    private func writePlaylist() {
        var text = "#EXTM3U\n#EXT-X-VERSION:3\n"
        text += "#EXT-X-TARGETDURATION:\(Int(ceil(targetDuration)))\n"
        text += "#EXT-X-MEDIA-SEQUENCE:\(mediaSequence)\n"
        for e in entries {
            text += String(format: "#EXTINF:%.3f,\n", e.duration)
            text += e.name + "\n"
        }
        let url = workDir.appendingPathComponent("index.m3u8")
        do {
            try text.data(using: .utf8)?.write(to: url, options: .atomic)
        } catch {
            logError("Failed to write playlist: \(error)")
        }
    }
}
