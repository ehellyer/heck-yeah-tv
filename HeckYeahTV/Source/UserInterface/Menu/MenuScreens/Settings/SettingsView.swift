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
    @Binding var appState: AppStateProvider
    @Environment(\.modelContext) private var viewContext
    
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    
    @Environment(\.dismiss) private var dismiss
    
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
    
    @Query(sort: \HomeRunDevice.deviceId, order: .forward) private var devices: [HomeRunDevice]
    
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
    }
}


#Preview {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()

    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        SettingsView(appState: $appState)
            .modelContext(swiftDataController.viewContext)
    }
}
