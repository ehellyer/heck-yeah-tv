// PureChannelSession.swift
// Heck Yeah TV
//
// Actor that manages per-channel live TS→HLS pipeline.
// MVP: H.264 video, one audio track, single program.

import Foundation
import SwiftData

@MainActor
final class PureChannelSessionManager {

    struct Session {
        let channelId: ChannelId
        let sourceURL: URL
        let workDir: URL
        let playlistURL: URL
        let pipeline: TSPipeline
        var lastAccess: Date
    }

    private var sessions: [ChannelId: Session] = [:]
    private var cleanupTimer: Timer?
    private let idleTimeout: TimeInterval = 120 // seconds
    private let viewContext = DataPersistence.shared.viewContext

    init() {
        startCleanupTimer()
    }

    deinit {
        // Hop to the main actor to call an actor-isolated method during teardown.
        Task { @MainActor in
            stopAll()
            cleanupTimer?.invalidate()
            cleanupTimer = nil
        }
    }

    func ensureSession(for channelId: ChannelId, proxyPort: Int) async throws -> (URL, Bool) {
        if let sess = sessions[channelId] {
            touch(channelId)
            return (sess.playlistURL, FileManager.default.fileExists(atPath: sess.playlistURL.path))
        }

        // Resolve source URL from SwiftData
        let predicate = #Predicate<IPTVChannel> { $0.id == channelId }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let model = try viewContext.fetch(descriptor).first else {
            throw NSError(domain: "PureHLS", code: 404, userInfo: [NSLocalizedDescriptionKey: "Channel not found"])
        }
        let source = model.url

        // Prepare work dir
        let base = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let workDir = base.appendingPathComponent("HYTV-PureHLS-\(channelId)")
        try? FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        let playlistURL = workDir.appendingPathComponent("index.m3u8")

        // Build pipeline
        let pipeline = try TSPipeline(sourceURL: source, workDir: workDir, config: .init(targetDuration: 4.0, windowSize: 6, proxyPort: proxyPort))

        let sess = Session(channelId: channelId, sourceURL: source, workDir: workDir, playlistURL: playlistURL, pipeline: pipeline, lastAccess: Date())
        sessions[channelId] = sess

        // Allow pipeline to produce first playlist
        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline && !FileManager.default.fileExists(atPath: playlistURL.path) {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        return (playlistURL, FileManager.default.fileExists(atPath: playlistURL.path))
    }

    func segmentURL(channelId: ChannelId, fileName: String) -> URL? {
        guard let sess = sessions[channelId] else { return nil }
        touch(channelId)
        return sess.workDir.appendingPathComponent(fileName)
    }

    func stopAll() {
        for (_, sess) in sessions {
            sess.pipeline.stop()
            try? FileManager.default.removeItem(at: sess.workDir)
        }
        sessions.removeAll()
    }

    // MARK: - Cleanup

    private func touch(_ channelId: ChannelId) {
        guard var s = sessions[channelId] else { return }
        s.lastAccess = Date()
        sessions[channelId] = s
    }

    private func startCleanupTimer() {
        cleanupTimer?.invalidate()
        // Use a scheduled timer and ensure we hop to the main actor before mutating state.
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupIdle()
            }
        }
    }

    private func cleanupIdle() {
        let now = Date()
        for (id, sess) in sessions {
            if now.timeIntervalSince(sess.lastAccess) > idleTimeout {
                logConsole("Cleaning idle session: \(id)")
                sess.pipeline.stop()
                try? FileManager.default.removeItem(at: sess.workDir)
                sessions.removeValue(forKey: id)
            }
        }
    }
}

// MARK: - TSPipeline (container for pipeline pieces)

final class TSPipeline {

    struct Config {
        let targetDuration: Double // seconds
        let windowSize: Int        // segments to keep
        let proxyPort: Int
    }

    private let sourceURL: URL
    private let workDir: URL
    private let config: Config

    private var reader: TSReader!
    private var programMap: ProgramMap!
    private var pesAssembler: PESAssembler!
    private var h264Parser: H264Parser!
    private var segmenter: TSSegmenter!
    private var playlist: LivePlaylist!

    private var running = true

    init(sourceURL: URL, workDir: URL, config: Config) throws {
        self.sourceURL = sourceURL
        self.workDir = workDir
        self.config = config

        // Build components
        playlist = LivePlaylist(workDir: workDir, targetDuration: config.targetDuration, windowSize: config.windowSize, segmentNamePattern: "segment%05d.ts")
        segmenter = TSSegmenter(workDir: workDir, playlist: playlist, targetDuration: config.targetDuration)
        h264Parser = H264Parser(onIDR: { [weak segmenter] in segmenter?.markKeyframe() })
        pesAssembler = PESAssembler(h264Parser: h264Parser, expectsH264Provider: { [weak segmenter] in
            return segmenter?.expectsH264 ?? false
        }, onPTS: { [weak segmenter] pts in
            segmenter?.updatePTS(pts)
        })
        programMap = ProgramMap(onProgramReady: { [weak self] (videoPID: UInt16, audioPID: UInt16?, isH264: Bool) in
            self?.segmenter.selectPIDs(video: videoPID, audio: audioPID, isH264: isH264)
        })
        reader = TSReader(sourceURL: sourceURL, onPacket: { [weak self] (packet: TSPacket) in
            guard let self else { return }
            // Feed PAT/PMT
            self.programMap.consume(packet: packet)
            // Feed PES for selected PIDs
            self.pesAssembler.consume(packet: packet, videoPID: self.segmenter.videoPID, audioPID: self.segmenter.audioPID)
            // Always forward raw TS packet to segmenter for muxed TS output
            self.segmenter.consume(packet: packet)
        }, onError: { err in
            logError("TSReader error: \(err)")
        })

        // Kick off
        reader.start()
    }

    func stop() {
        guard running else { return }
        running = false
        reader.stop()
        segmenter.finishAndClose()
    }
}
