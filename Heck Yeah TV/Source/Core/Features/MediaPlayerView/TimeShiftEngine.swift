//
//  TimeShiftEngine.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/14/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

#if os(tvOS)
@preconcurrency import TVVLCKit
#elseif os(macOS)
@preconcurrency import VLCKit
import AppKit
#else
@preconcurrency import MobileVLCKit
import UIKit
#endif



/// Two-player timeshift engine:
/// - recorder: pulls live stream and writes to a temp .ts file via `sout`
/// - playback: plays the *growing* file; pause/resume only affect playback
@MainActor
final class TimeShiftEngine: NSObject, ObservableObject {
    
    @Published private(set) var state: PlayerState = .idle
    @Published private(set) var tempFileURL: URL?
    
    lazy var platformView: PlatformView = {
        let view = PlatformView()
#if os(macOS)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
#else
        view.backgroundColor = .black
#endif
        return view
    }()
    
    var mediaURL: URL? {
        return self.recorder.media?.url
    }
    private let recorder = VLCMediaPlayer()   // headless writer with :sout
    private let playback = VLCMediaPlayer()   // player for the temp file
    
    private var pollTask: Task<Void, Never>?
    
    /// Bytes required before we attempt playback (tune to taste)
    private let minStartBytes: Int64 = 512 * 1024 // 512 KB
    
    // MARK: Public API
    
    func start(streamURL: URL) {
        
        if case .recordingAndPlaying = state { return }
        if case .pausedPlayback = state { resume(); return }
        
        state = .starting
        
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("HeckYeahTV", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent(UUID().uuidString + ".ts")
        tempFileURL = file
        
        let media = VLCMedia(url: streamURL)
        let sout = "#std{access=file,mux=ts,dst=\(file.path)}"
        media.addOptions([
            "sout": sout,                       // Default stream output chain. You can enter here a default stream output chain. Refer to the documentation to learn how to build such chains. Warning: this chain will be enabled for all streams
            "sout-all": true,                   // Enable streaming of all ES (default enabled) Stream all elementary streams (video, audio and subtitles)
            "sout-keep": true,                  // Keep stream output open;  This allows you to keep an unique stream output instance across multiple playlist item (automatically insert the gather stream output if not specified)
            "network-caching": 1000,            // [0 .. 60000] Network caching (ms); Caching value for network resources, in milliseconds.
            "live-caching": 1000,               // [0 .. 60000] Live capture caching (ms); Caching value for cameras and microphones, in milliseconds.
            "avcodec-hw": "any",                  // prefer hardware decode when possible
            "drop-late-frames": true,             // reduce CPU spikes under load
            "skip-frames": true                  // allow frame skipping under pressure
        ])
        
        recorder.media = media
        recorder.drawable = nil // headless writer
        recorder.audio?.isMuted = true
        recorder.play()
        
        playback.drawable = self.platformView
        
        startPollingUntilPlayable(fileURL: file)
    }
    
    /// Pause only the playback; recording continues in the background.
    func pause() {
        guard state == .recordingAndPlaying else { return }
        playback.pause()
        state = .pausedPlayback
    }
    
    /// Resume playback from the current position.
    func resume() {
        guard state == .pausedPlayback else { return }
        playback.play()
        state = .recordingAndPlaying
    }
    
    /// Stop both players and delete the temp file.
    func stopAndDelete() {
        state = .stopping
        pollTask?.cancel()
        pollTask = nil
        
        playback.stop()
        recorder.stop()
        
        playback.drawable = nil
        
        if let url = tempFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        tempFileURL = nil
        state = .idle
    }
    
    // MARK: Internals
    
    private func startPollingUntilPlayable(fileURL: URL) {
        // Ensure file exists so VLC can append immediately
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25s
                let size = self.fileSize(at: fileURL)
                if size >= self.minStartBytes {
                    self.beginPlayback(of: fileURL)
                    break
                }
            }
        }
    }
    
    @MainActor
    private func beginPlayback(of fileURL: URL) {
        let fileMedia = VLCMedia(url: fileURL)
        fileMedia.addOptions([
            "file-caching": 500,                    // [0 .. 60000] File caching (ms) Caching value for local files, in milliseconds.
            "input-fast-seek": true,                // Fast seek(default disabled) Favor speed over precision while seeking
            "demux": "ts",                           // Demultiplexers are used to separate the "elementary" streams (like audio and video streams). You can use it if the correct demuxer is not automatically detected. You should not set this as a global option unless you really know what you are doing.
            
            "no-lua": true,
            "no-video-title-show": true,
            "avcodec-hw": "any",                  // prefer hardware decode when possible
            "drop-late-frames": true,             // reduce CPU spikes under load
            "skip-frames": true,                  // allow frame skipping under pressure
            "deinterlace": false
        ])
        playback.media = fileMedia
        playback.play()
        state = .recordingAndPlaying
    }
    
    // Lightweight synchronous size check (fine at 4Hz)
    private func fileSize(at url: URL) -> Int64 {
        let attrs = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        return (attrs[.size] as? NSNumber)?.int64Value ?? 0
    }
}
