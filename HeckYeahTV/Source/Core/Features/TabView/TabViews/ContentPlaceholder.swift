//
//  ContentPlaceholder.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

struct ContentPlaceholder: View {
    let title: String
    let symbol: String
    
    var body: some View {
        ZStack {
            Spacer()
            
            #if os(tvOS)
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: symbol).font(.system(size: 48))
                    Text(title).font(.largeTitle.bold())
                }
                Text("For Development Only: Replace this with your real \(title) screen.")
                    .foregroundStyle(.secondary)
            }
            
            #else
            
            VStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 48))
                Text(title).font(.largeTitle.bold())
                Text("For Development Only: Replace this with your real \(title) screen.")
                    .foregroundStyle(.secondary)
            }
            
            #endif
        }
    }
}
