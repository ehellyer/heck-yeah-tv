// PureHLSProxyServer.swift
// Heck Yeah TV
//
// Minimal HTTP server using Network.framework.
// Routes:
//   GET /channel/{id}.m3u8  -> serves rolling playlist for ChannelId
//   GET /segment/{id}/{f}.ts -> serves segment file bytes
//
// This server delegates per-channel work to PureChannelSessionManager.

import Foundation
import Network

@MainActor
final class PureHLSProxyServer {
    static let shared = PureHLSProxyServer()
    private init() {}

    private var listener: NWListener?
    private var port: NWEndpoint.Port = 8089
    private let queue = DispatchQueue(label: "PureHLSProxyServer.queue")

    private let sessions = PureChannelSessionManager()

    func start(port: Int) {
        guard listener == nil else { return }
        guard let p = NWEndpoint.Port(rawValue: UInt16(port)) else {
            logError("Invalid proxy port: \(port)")
            return
        }
        self.port = p
        do {
            let params = NWParameters.tcp
            let listener = try NWListener(using: params, on: p)
            listener.stateUpdateHandler = { [weak self] state in
                guard self != nil else { return }
                switch state {
                    case .ready:
                        logConsole("PureHLSProxyServer listening on 127.0.0.1:\(port)")
                    case .failed(let err):
                        logError("PureHLSProxyServer failed: \(err)")
                    default: break
                }
            }
            listener.newConnectionHandler = { [weak self] conn in
                // Hop to main actor to call main-actor isolated methods
                Task { @MainActor in
                    self?.handle(connection: conn)
                }
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            logError("Failed to start PureHLSProxyServer: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        sessions.stopAll()
        logConsole("PureHLSProxyServer stopped")
    }

    // MARK: - Connection handling

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            // This completion runs on self.queue; hop to main actor before touching actor state.
            Task { @MainActor in
                guard let self else { return }
                if let data, !data.isEmpty {
                    self.processRequest(data: data, on: connection)
                } else {
                    connection.cancel()
                }
                if isComplete || error != nil {
                    connection.cancel()
                }
            }
        }
    }

    private func processRequest(data: Data, on connection: NWConnection) {
        guard let requestText = String(data: data, encoding: .utf8) else {
            send(status: 400, headers: [:], body: Data(), on: connection); return
        }
        let lines = requestText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            send(status: 400, headers: [:], body: Data(), on: connection); return
        }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else {
            send(status: 400, headers: [:], body: Data(), on: connection); return
        }
        let method = parts[0]
        let path = String(parts[1])

        guard method == "GET" else {
            send(status: 405, headers: [:], body: Data(), on: connection); return
        }

        if path.hasPrefix("/channel/") && path.hasSuffix(".m3u8") {
            handlePlaylist(path: path, on: connection)
        } else if path.hasPrefix("/segment/") && path.hasSuffix(".ts") {
            handleSegment(path: path, on: connection)
        } else if path == "/" || path == "/health" {
            send(status: 200, headers: ["Content-Type": "text/plain; charset=utf-8"], body: Data("OK\n".utf8), on: connection)
        } else {
            send(status: 404, headers: [:], body: Data(), on: connection)
        }
    }

    private func handlePlaylist(path: String, on connection: NWConnection) {
        // /channel/{id}.m3u8
        guard let last = path.split(separator: "/").last else {
            send(status: 400, headers: [:], body: Data(), on: connection); return
        }
        let channelId = String(last).replacingOccurrences(of: ".m3u8", with: "")

        Task { @MainActor in
            do {
                let (playlistURL, exists) = try await sessions.ensureSession(for: channelId, proxyPort: Int(port.rawValue))
                guard exists, let data = try? Data(contentsOf: playlistURL) else {
                    send(status: 503, headers: [:], body: Data(), on: connection); return
                }
                send(status: 200, headers: ["Content-Type": "application/vnd.apple.mpegurl"], body: data, on: connection)
            } catch {
                logError("Playlist error: \(error)")
                send(status: 500, headers: [:], body: Data(), on: connection)
            }
        }
    }

    private func handleSegment(path: String, on connection: NWConnection) {
        // /segment/{id}/{file}.ts
        let comps = path.split(separator: "/")
        guard comps.count >= 3 else {
            send(status: 400, headers: [:], body: Data(), on: connection); return
        }
        let channelId = String(comps[1])
        let file = String(comps[2])

        Task { @MainActor in
            if let url = sessions.segmentURL(channelId: channelId, fileName: file),
               let data = try? Data(contentsOf: url) {
                send(status: 200, headers: ["Content-Type": "video/MP2T"], body: data, on: connection)
            } else {
                send(status: 404, headers: [:], body: Data(), on: connection)
            }
        }
    }

    // These helpers don’t touch actor state; mark as nonisolated to allow calling from any thread safely.
    nonisolated private func send(status: Int, headers: [String: String], body: Data, on connection: NWConnection) {
        var response = "HTTP/1.1 \(status) \(reason(status))\r\n"
        var hdrs = headers
        hdrs["Content-Length"] = "\(body.count)"
        hdrs["Connection"] = "close"
        if hdrs["Content-Type"] == nil { hdrs["Content-Type"] = "application/octet-stream" }
        for (k, v) in hdrs { response += "\(k): \(v)\r\n" }
        response += "\r\n"
        var out = Data(response.utf8)
        out.append(body)
        connection.send(content: out, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    nonisolated private func reason(_ status: Int) -> String {
        switch status {
            case 200: return "OK"
            case 400: return "Bad Request"
            case 404: return "Not Found"
            case 405: return "Method Not Allowed"
            case 500: return "Internal Server Error"
            case 503: return "Service Unavailable"
            default:  return "Status"
        }
    }
}
