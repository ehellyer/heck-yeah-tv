//
//  LoadImageAsync.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/7/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct LoadImageAsync: View {
    
    let url: URL?
    let defaultImage: Image?
    let showProgressView: Bool
    
    @State private var imageLoadTask: Task<Void, Never>? = nil
    @State private var loadedImage: Image?
    @State private var isLoading = true
    
    @Injected(\.attachmentController)
    private var attachmentController: AttachmentController
    
    init(url: URL?,
         defaultImage: Image? = nil,
         showProgressView: Bool = false) {
        
        self.url = url
        self.defaultImage = defaultImage
        self.showProgressView = showProgressView
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                if showProgressView {
                    ProgressView()
                }
            } else {
                if let loadedImage {
                    loadedImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    if let defaultImage {
                        defaultImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
        }
        .onAppear() {
            isLoading = true
            let hashId = url.hashValue
            imageLoadTask?.cancel()
            imageLoadTask = Task.detached {
                if PreviewDetector.isRunningInPreview {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
                let image = try? await attachmentController.fetchImage(url)
                guard !Task.isCancelled, url.hashValue == hashId, let image else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
                await MainActor.run {
                    isLoading = false
                    loadedImage = image
                }
            }
        }
        .onDisappear {
            imageLoadTask?.cancel()
        }
    }
}

#Preview {
    ZStack {
        Color.gray.edgesIgnoringSafeArea(.all)
        let url = URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTautuE9CFa_e3-R9rmr1ohpatXGj6m8xWyqg&s")!
        
        LoadImageAsync(url: url,
                       defaultImage: Image(systemName: "tv.circle.fill"),
                       showProgressView: true)
    }
}
