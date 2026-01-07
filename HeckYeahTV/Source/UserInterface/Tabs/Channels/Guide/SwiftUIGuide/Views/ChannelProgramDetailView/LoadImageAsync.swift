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
    
    @Injected(\.attachmentController)
    private var attachmentController: AttachmentController
    
    @State private var isLoading = true
    
    // Custom initializer with default values
    init(url: URL?, defaultImage: Image? = nil, showProgressView: Bool = false) {
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
                        .cornerRadius(15)
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
        
        LoadImageAsync(url: URL(string: "https://media.istockphoto.com/id/636379014/photy/hands-forming-a-heart-shape-with-sunset-silhouette.jpg?s=612x612&w=0&k=20&c=CgjWWGEasjgwia2VT7ufXa10azba2HXmUDe96wZG8F0=")!,
                       defaultImage: Image(systemName: "tv.circle.fill"),
                       showProgressView: true)
        
    }
}
