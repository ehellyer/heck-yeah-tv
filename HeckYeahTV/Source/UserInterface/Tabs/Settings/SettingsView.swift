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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCountryPicker = false
    @State private var isScanningForTuners: Bool = false
    @State private var isUpdatingIPTVChannels: Bool = false
    
#if os(iOS)
    let titleColor: Color = Color.sectionTitle
#elseif os(macOS)
    let titleColor: Color = Color.sectionTitle
#elseif os(tvOS)
    let titleColor: Color = .white
#endif
    
    @Query(sort: \HDHomeRunServer.deviceId, order: .forward) private var devices: [HDHomeRunServer]
    
    var body: some View {
        Form {
            
            Section {
                HStack {
                    Text("Total IPTV Channels")
                        .modifier(SectionTextStyle())
                    Spacer()
                    if not(isUpdatingIPTVChannels) {
                        Text("13,600")
                            .modifier(SectionTextStyle())
                    }
                }
                .modifier(SectionTextContainerStyle())
                
                Button {
                    Task {
                        isUpdatingIPTVChannels = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            isUpdatingIPTVChannels = false
                        }
                    }
                } label: {
                    HStack {
                        Text("Update IPTV channels")
                        Spacer()
                        if isUpdatingIPTVChannels {
                            ProgressView()
                                .tint(.primary)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .buttonStyle(SectionButtonStyle())
            } header: {
                Text("IPTV Channels")
                    .foregroundStyle(titleColor)
            }
#if os(tvOS)
            //.listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
#endif
            
            
            Section {
                
                Button {
                    appState.scanForTuners.toggle()
                } label: {
                    HStack {
                        Text("Scan for tuners at launch")
                        Spacer()
                        if appState.scanForTuners {
                            Text("On")
                        } else {
                            Text("Off")
                        }
                    }
                }
                .buttonStyle(SectionButtonStyle())
                
                Button {
                    Task {
                        isScanningForTuners = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            isScanningForTuners = false
                        }
                    }
                } label: {
                    HStack {
                        Text("Scan for tuners")
                        Spacer()
                        if isScanningForTuners {
                            ProgressView()
                                .tint(.primary)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .buttonStyle(SectionButtonStyle())
            }
            header: {
                Text("HD HomeRun Tuners")
                    .foregroundStyle(titleColor)
            }
#if os(tvOS)
            //.listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
#endif
            
            if not(isScanningForTuners) {
                Section {
                    
                    ForEach(devices) { device in
                        @Bindable var bindableDevice = device
                        
                        Button {
                            device.includeChannelLineUp.toggle()
                        } label: {
                            HStack {
                                Text("\(device.deviceId) \(device.friendlyName)")
                                Spacer()
                                if device.includeChannelLineUp {
                                    Text("On")
                                } else {
                                    Text("Off")
                                }
                            }
                        }
                        .buttonStyle(SectionButtonStyle())
                    }
                    
                    if devices.isEmpty {
                        HStack {
                            Text("No local tuners found")
                            Spacer()
                        }
#if os(tvOS)
                        .foregroundStyle(.white)
                        .padding()
                        .background(
                            Capsule()
                                .fill(.guideBackgroundNoFocus)
                        )
#endif
                    }
                }
                header: {
                    Text("Discovered LAN Tuners")
                        .foregroundStyle(titleColor)
                }
#if os(tvOS)
                //.listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
#endif
            }
        }
    }
}

#Preview {
    
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    let mockData = MockDataPersistence(appState: appState)
    
    
    return TVPreviewView() {
        SettingsView(appState: $appState)
            .environment(\.modelContext, mockData.context)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
    }
    
    
}
