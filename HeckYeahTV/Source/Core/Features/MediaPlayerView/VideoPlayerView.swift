//
//  VideoPlayerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import AVKit
import SwiftData

struct VideoPlayerView: View {
    
    //MARK: - Binding and State
    @Environment(\.scenePhase) private var scenePhase
    @Binding var appState: SharedAppState
    @State private var player = AVPlayer()
    
    @State private var viewContext = DataPersistence.shared.viewContext

    // Observer holder
    @State private var playerDiagnostics = PlayerDiagnostics()
    
    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .onAppear {
                    playerDiagnostics.attach(to: player)
                    setPlayerForChannel(channelId: appState.selectedChannel)
                }
            
                .onDisappear {
                    player.pause()
                    playerDiagnostics.detach()
                }
            
                .onChange(of: appState.isPlayerPaused) { _, newValue in
                    if newValue {
                        player.pause()
                    } else {
                        player.play()
                    }
                }
            
                .onChange(of: appState.selectedChannel) { _, newValue in
                    setPlayerForChannel(channelId: newValue)
                }
        }
    }
}

extension VideoPlayerView {
    private func setPlayerForChannel(channelId: ChannelId?) {
        guard let channelId, let url = resolveChannelURL(id: channelId) else {
            player.replaceCurrentItem(with: nil)
            return
        }
        
        Task { @MainActor in
            // If HDHomeRun channel and proxy enabled, rewrite to local HLS
            let finalInputURL: URL = {
                if appState.useHLSProxy, isHDHomeRunChannel(id: channelId) {
                    let port = appState.hlsProxyPort
                    return URL(string: "http://127.0.0.1:\(port)/channel/\(channelId).m3u8") ?? url
                }
                return url
            }()
            
            // Resolve .m3u if needed; .m3u8 or direct URLs pass through
            let finalURL: URL
            do {
                finalURL = try await PlaylistResolver.resolve(url: finalInputURL)
            } catch {
                // If resolution fails, try original URL as a fallback
                finalURL = finalInputURL
            }
            
            // Build asset with useful network options
            let assetOptions: [String: Any] = [
                AVURLAssetAllowsConstrainedNetworkAccessKey: true,
                AVURLAssetAllowsExpensiveNetworkAccessKey: true
            ]
            let asset = AVURLAsset(url: finalURL, options: assetOptions)
            let item = AVPlayerItem(asset: asset)
            
            // Swap the current item; keep player instance
            player.replaceCurrentItem(with: item)
            
            // Autoplay if not paused
            if !appState.isPlayerPaused {
                player.play()
            }
        }
    }
    
    private func resolveChannelURL(id: ChannelId) -> URL? {
        let predicate = #Predicate<IPTVChannel> { $0.id == id }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? viewContext.fetch(descriptor).first?.url
    }
    
    private func isHDHomeRunChannel(id: ChannelId) -> Bool {
        let predicate = #Predicate<IPTVChannel> { $0.id == id }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let ch = try? viewContext.fetch(descriptor).first {
            return ch.source == .homeRunTuner
        }
        return false
    }
}

// MARK: - PlayerDiagnostics

@MainActor
final class PlayerDiagnostics {
    private var player: AVPlayer?
    private var currentItem: AVPlayerItem?
    private var currentURL: URL?
    
    private var itemStatusObs: NSKeyValueObservation?
    private var playerStatusObs: NSKeyValueObservation?
    
    private var failedToEndObserver: Any?
    private var stalledObserver: Any?
    private var newErrorLogEntryObserver: Any?
    private var newAccessLogEntryObserver: Any?
    
    func attach(to player: AVPlayer) {
        self.player = player
        
        // Observe player.status
        playerStatusObs = player.observe(\.status, options: [.initial, .new]) { [weak self] player, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.log("AVPlayer.status = \(self.describe(player.status))")
                if let err = player.error as NSError? {
                    self.logNSError("AVPlayer.error", err)
                }
            }
        }
        
        // Hook current item if present
        if let item = player.currentItem {
            observe(item: item, url: nil)
        }
    }
    
    func observe(item: AVPlayerItem, url: URL?) {
        // Clear prior
        clearItemObservers()
        
        self.currentItem = item
        self.currentURL = url
        
        // Observe item.status
        itemStatusObs = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.log("AVPlayerItem.status = \(self.describe(item.status)) url=\(self.currentURL?.absoluteString ?? "unknown")")
                switch item.status {
                    case .readyToPlay:
                        self.dumpAccessLog(item)
                    case .failed:
                        if let err = item.error as NSError? {
                            self.logNSError("AVPlayerItem.error", err)
                        }
                        self.dumpErrorLog(item)
                    default:
                        break
                }
            }
        }
        
        // Notifications
        failedToEndObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime,
                                                                     object: item,
                                                                     queue: .main) { [weak self] note in
            guard let self else { return }
            DispatchQueue.main.async {
                let err = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError
                self.log("Notification: AVPlayerItemFailedToPlayToEndTime")
                if let err { self.logNSError("FailedToPlayToEndTime.error", err) }
                self.dumpErrorLog(item)
            }
        }
        
        stalledObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemPlaybackStalled,
                                                                 object: item,
                                                                 queue: .main) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.log("Notification: AVPlayerItemPlaybackStalled")
                self.dumpAccessLog(item)
            }
        }
        
        newErrorLogEntryObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemNewErrorLogEntry,
                                                                          object: item,
                                                                          queue: .main) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.log("Notification: AVPlayerItemNewErrorLogEntry")
                self.dumpErrorLog(item)
            }
        }
        
        newAccessLogEntryObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemNewAccessLogEntry,
                                                                           object: item,
                                                                           queue: .main) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.log("Notification: AVPlayerItemNewAccessLogEntry")
                self.dumpAccessLog(item)
            }
        }
    }
    
    func detach() {
        clearItemObservers()
        playerStatusObs?.invalidate()
        playerStatusObs = nil
        player = nil
    }
    
    private func clearItemObservers() {
        itemStatusObs?.invalidate()
        itemStatusObs = nil
        
        if let o = failedToEndObserver { NotificationCenter.default.removeObserver(o) }
        if let o = stalledObserver { NotificationCenter.default.removeObserver(o) }
        if let o = newErrorLogEntryObserver { NotificationCenter.default.removeObserver(o) }
        if let o = newAccessLogEntryObserver { NotificationCenter.default.removeObserver(o) }
        failedToEndObserver = nil
        stalledObserver = nil
        newErrorLogEntryObserver = nil
        newAccessLogEntryObserver = nil
        
        currentItem = nil
        currentURL = nil
    }
    
    // MARK: - Logging helpers
    
    private func log(_ message: String) {
#if DEBUG
        print("[AVP] \(message)")
#endif
    }
    
    private func logNSError(_ prefix: String, _ error: NSError) {
        log("\(prefix): domain=\(error.domain) code=\(error.code) desc=\(error.localizedDescription)")
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            log("  underlying: domain=\(underlying.domain) code=\(underlying.code) desc=\(underlying.localizedDescription)")
        }
        if let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            log("  failingURL: \(failingURL.absoluteString)")
        }
    }
    
    private func dumpAccessLog(_ item: AVPlayerItem) {
        guard let log = item.accessLog() else { return }
        for (idx, e) in log.events.enumerated() {
            self.log("""
            AccessLog[\(idx)] uri=\(e.uri ?? "nil")
              playbackType=\(e.playbackType ?? "nil")
              segmentsDownloaded=\(e.numberOfMediaRequests)
              transferBytes=\(e.numberOfBytesTransferred)
              indicatedBitrate=\(e.indicatedBitrate)
              observedBitrate=\(e.observedBitrate)
              serverAddress=\(e.serverAddress ?? "nil")
              startupTime=\(e.startupTime)
              playbackSessionID=\(e.playbackSessionID ?? "nil")
            """)
        }
    }
    
    private func dumpErrorLog(_ item: AVPlayerItem) {
        if let err = item.error as NSError? {
            logNSError("Item.error", err)
        }
        guard let log = item.errorLog() else { return }
        for (idx, e) in log.events.enumerated() {
            self.log("""
            ErrorLog[\(idx)] uri=\(e.uri ?? "nil")
              serverAddress=\(e.serverAddress ?? "nil")
              errorStatusCode=\(e.errorStatusCode)
              errorDomain=\(e.errorDomain)
              errorComment=\(e.errorComment ?? "nil")
            """)
        }
    }
    
    private func describe(_ status: AVPlayer.Status) -> String {
        switch status {
            case .unknown: return "unknown"
            case .readyToPlay: return "readyToPlay"
            case .failed: return "failed"
            @unknown default: return "unknown(new)"
        }
    }
    
    private func describe(_ status: AVPlayerItem.Status) -> String {
        switch status {
            case .unknown: return "unknown"
            case .readyToPlay: return "readyToPlay"
            case .failed: return "failed"
            @unknown default: return "unknown(new)"
        }
    }
}

