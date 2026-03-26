//
//  HDHomeRunProbeTestView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 3/24/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.

import SwiftUI

#if DEBUG
struct HDHomeRunProbeTestView: View {
    @State private var isRunning = false
    @State private var logOutput: String = "Ready to test HDHomeRun discovery..."
    @State private var targetIP = "192.168.78.220"
    @State private var useBroadcast = true

    var body: some View {
        VStack(spacing: 20) {
            Text("HDHomeRun Probe Test")
                .font(.largeTitle)
                .padding()

            HStack {
                Toggle("Use Broadcast", isOn: $useBroadcast)
                    .toggleStyle(.switch)

                if !useBroadcast {
                    TextField("Target IP", text: $targetIP)
#if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
#endif
                        .frame(width: 200)
                }
            }
            .padding()

            Button(action: runTest) {
                HStack {
                    if isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isRunning ? "Testing..." : "Run Discovery Test")
                }
            }
            .disabled(isRunning)
            .buttonStyle(.borderedProminent)

            ScrollView {
                Text(logOutput)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
        .padding()
    }

    private func runTest() {
        isRunning = true
        logOutput = "=== Starting HDHomeRun Discovery Test ===\n"

        Task {
            let probe = HDHomeRunProbe()

            do {
                let testIP = useBroadcast ? nil : targetIP

                if let testIP = testIP {
                    appendLog("🎯 Testing unicast discovery to \(testIP)")
                } else {
                    appendLog("📡 Testing broadcast discovery")
                }
                appendLog("⏱️  Discovery timeout: 3 seconds\n")

                let devices = try await probe.discoverDevices(targetIP: testIP)

                appendLog("\n✅ SUCCESS! Found \(devices.count) device(s)\n")

                for (index, device) in devices.enumerated() {
                    let deviceTypeName = device.deviceType == 1 ? "Tuner" : (device.deviceType == 5 ? "Storage" : "Unknown")
                    appendLog("Device #\(index + 1):")
                    appendLog("  Device ID: \(device.deviceID)")
                    appendLog("  Device Type: \(device.deviceType) (\(deviceTypeName))")
                    appendLog("  Base URL: \(device.baseURL)")
                    appendLog("  IP Address: \(device.ipAddress)")
                    appendLog("")
                }

            } catch let error as HDHomeRunProbe.ProbeError {
                appendLog("\n❌ Discovery failed with error:")
                appendLog("   \(error.localizedDescription)")
            } catch {
                appendLog("\n❌ Unexpected error:")
                appendLog("   \(error.localizedDescription)")
            }

            appendLog("\n=== Test Complete ===")
            isRunning = false
        }
    }

    private func appendLog(_ message: String) {
        Task { @MainActor in
            logOutput += message + "\n"
        }
    }
}

#Preview {
    HDHomeRunProbeTestView()
}
#endif
