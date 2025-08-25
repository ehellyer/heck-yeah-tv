//
//  Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//

import Foundation

protocol Channelable {
    var idHint: String { get }
    var titleHint: String { get }
    var numberHint: String? { get }     
    var urlHint: URL { get }
    var isHDHint: Bool { get }
    var hasDRMHint: Bool { get }
}
