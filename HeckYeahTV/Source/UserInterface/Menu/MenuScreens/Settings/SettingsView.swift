//
//  SettingsView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/21/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var devices: [HomeRunDevice] = []
    @State private var showingCountryPicker = false
    @State private var isScanningForTuners: Bool = false
    @State private var isUpdatingChannels: Bool = false
    
#if os(iOS)
    let titleColor: Color = Color.sectionTitle
#elseif os(macOS)
    let titleColor: Color = Color.sectionTitle
#elseif os(tvOS)
    let titleColor: Color = .white
#endif
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Text("IPTV")
                .foregroundStyle(titleColor)
            
            
            HStack {
                Text("Total IPTV Channels")
                
                if not(isUpdatingChannels) {
                    Text("\(swiftDataController.totalChannelCount)")
                }
                Spacer()
            }
            
            Button {
                Task {
                    isUpdatingChannels = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        isUpdatingChannels = false
                    }
                }
            } label: {
                Text("Update IPTV channels")
            }
            .foregroundColor(.blue)
            .padding(.bottom, 40)
            
            
            
            Text("HD HomeRun")
            

            Button {
                // Scan for HDHomeRun Tuners
            } label: {
                Text("Scan for tuners")
            }
            .foregroundColor(.blue)

            
            ForEach(devices, id: \.deviceId) { device in
                @Bindable var bindableDevice = device
                
                let channelCount: Int = (try? swiftDataController.totalChannelCountFor(deviceId: device.deviceId)) ?? 0
                
                HStack {
                    Text("\(device.deviceId) \(device.friendlyName)")
                    Spacer()
                    Text("Ch: \(channelCount)")
                }


                Button {
                    device.includeChannelLineUp.toggle()
                } label: {
                    HStack {
                        Text("Include channel lineup")
                        Spacer()

                        
                        if device.includeChannelLineUp {
                            Image(systemName: "checkmark.square.fill")
                        } else {
                            Image(systemName: "square")
                        }
                    }
                }
                .foregroundColor(.blue)
                
            }
            
            if devices.isEmpty {
                HStack {
                    Text("No local tuners found")
                    Spacer()
                }

            }
            Spacer()
        }
        .background(.red)
        .onAppear() {
            self.devices = (try? swiftDataController.homeRunDevices()) ?? []
        }
    }
}


#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        SettingsView()
    }
}
