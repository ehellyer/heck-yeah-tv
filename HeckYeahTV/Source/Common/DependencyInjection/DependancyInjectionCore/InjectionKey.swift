//
//  InjectionKey.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 12/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//
//  Dependency injection in Swift using modern Swift syntax developed by Antoine Van Der Lee
//  https://www.avanderlee.com/swift/dependency-injection/

import Foundation

protocol InjectionKey {
    
    /// The associated type representing the type of the dependency injects key's value.
    associatedtype Value
    
    /// The default value for the dependency injection key.
    static var currentValue: Self.Value { get set }
}
