//
//  Injected.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 12/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//
//  Dependency injection in Swift using modern Swift syntax developed by Antoine Van Der Lee
//  https://www.avanderlee.com/swift/dependency-injection/

import Foundation

@propertyWrapper
struct Injected<T> {
    
    private let keyPath: WritableKeyPath<InjectedValues, T>
    
    var wrappedValue: T {
        get {
            InjectedValues[keyPath]
        }
        set {
            InjectedValues[keyPath] = newValue
        }
    }
    
    init(_ keyPath: WritableKeyPath<InjectedValues, T>) {
        self.keyPath = keyPath
    }
}
