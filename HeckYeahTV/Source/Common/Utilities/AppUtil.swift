//
//  AppUtil.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

//------------------------------------------------------------------------------------------------------------------------
//       __    __                      __              __      __                    __              ________  __     __
//      |  \  |  \                    |  \            |  \    /  \                  |  \            |        \|  \   |  \
//      | $$  | $$  ______    _______ | $$   __        \$$\  /  $$______    ______  | $$____         \$$$$$$$$| $$   | $$
//      | $$__| $$ /      \  /       \| $$  /  \        \$$\/  $$/      \  |      \ | $$    \          | $$   | $$   | $$
//      | $$    $$|  $$$$$$\|  $$$$$$$| $$_/  $$         \$$  $$|  $$$$$$\  \$$$$$$\| $$$$$$$\         | $$    \$$\ /  $$
//      | $$$$$$$$| $$    $$| $$      | $$   $$           \$$$$ | $$    $$ /      $$| $$  | $$         | $$     \$$\  $$
//      | $$  | $$| $$$$$$$$| $$_____ | $$$$$$\           | $$  | $$$$$$$$|  $$$$$$$| $$  | $$         | $$      \$$ $$
//      | $$  | $$ \$$     \ \$$     \| $$  \$$\          | $$   \$$     \ \$$    $$| $$  | $$         | $$       \$$$
//       \$$   \$$  \$$$$$$$  \$$$$$$$ \$$   \$$           \$$    \$$$$$$$  \$$$$$$$ \$$   \$$          \$$        \$
//
//
//
//
//  Put here any global functions or values that are application agnostic.
//
//  ACID TEST: Can you copy paste the function or value into another app and it work without modification or dependencies?
//
//------------------------------------------------------------------------------------------------------------------------

/// Creates a function for not (!).
let not = (!)

/// Returns the name of the object as a string.
func stringName<T>(_ object: T) -> String {
    return String(describing: type(of: object))
}

/// A value in nanoseconds representing 0.01s or 10ms.
///
/// This is the time to sleep before executing a task, providing a small delay for
/// the the task to be cancelled because it was replaced by a similar subsequent task.
let debounceNS: UInt64 = 10_000_000 //0.01 seconds
