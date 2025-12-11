//
//  InjectedValues.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 12/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//
//  Dependency injection in Swift using modern Swift syntax developed by Antoine Van Der Lee
//  https://www.avanderlee.com/swift/dependency-injection/

import Foundation

struct InjectedValues {
    
    /// This is only used as an access to the computed properties with extensions of `InjectedValues`.
    private static var current = InjectedValues()
    
    /// A static subscript for updating the `currentValue` of `InjectionKey` instances.
    static subscript<K>(key: K.Type) -> K.Value where K : InjectionKey {
        get {
            key.currentValue
        }
        set {
            key.currentValue = newValue
        }
    }
    
    /// A static subscript accessor for updating and referencing dependencies directly.
    static subscript<T>(_ keyPath: WritableKeyPath<InjectedValues, T>) -> T {
        get {
            current[keyPath: keyPath]
        }
        set {
            current[keyPath: keyPath] = newValue
        }
    }
}
