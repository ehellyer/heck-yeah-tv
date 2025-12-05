//
//  AttachmentControllerInjectionConfig.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

private struct AttachmentControllerInjectionKey: InjectionKey {
    static var currentValue: AttachmentController = AttachmentController()
}

extension InjectedValues {
    var attachmentController: AttachmentController {
        get { Self[AttachmentControllerInjectionKey.self] }
        set { Self[AttachmentControllerInjectionKey.self] = newValue }
    }
}
