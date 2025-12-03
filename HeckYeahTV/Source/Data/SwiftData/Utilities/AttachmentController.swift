//
//  AttachmentController.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Hellfire

class AttachmentController {
    
//    deinit {
//        logDebug("Deallocated")
//    }
    
    //MARK: - Internal API
    
    /// Fetches an image with the appropriate disk caching option.
    func fetchImage(_ attachmentURL: URL?, cachePolicyType: CachePolicyType = .month) async throws -> Image? {
        
        guard let pfImage = try await fetchPlatformImage(attachmentURL, cachePolicyType: cachePolicyType) else
        {
            return nil
        }
        
#if canImport(UIKit)
        return Image(uiImage: pfImage)
#elseif canImport(AppKit)
        return Image(nsImage: pfImage)
#endif
    }
    

    func fetchPlatformImage(_ attachmentURL: URL?, cachePolicyType: CachePolicyType = .month) async throws -> PlatformImage? {
        
        guard let attachmentURL else {
            return nil
        }
        
        // Setup the request
        let request = NetworkRequest(url: attachmentURL,
                                     method: .get,
                                     cachePolicyType: cachePolicyType,
                                     timeoutInterval: 10.0,
                                     headers: [HTTPHeader(name: "accept-type", value: "image/png, image/jpeg, image/*;q=0.8")])
        
        // Make the call
        let response = try await SessionInterface.sharedInstance.execute(request)
        guard let data = response.body, let pfImage = PlatformImage(data: data) else {
            return nil
        }
        
        return pfImage
    }
}
