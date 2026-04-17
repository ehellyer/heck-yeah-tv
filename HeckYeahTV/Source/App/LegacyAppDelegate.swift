//
//  LegacyAppDelegate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/16/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//


/*
    EJH - Developer note:
 
    This file was added to support Firebase SDK.  Namely at this time we are using Crashlytics and Analytics from the Firebase SDK.
 */


#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
import FirebaseCore


#if canImport(AppKit)
typealias AppDelegateAlias = NSApplicationDelegate
#elseif canImport(UIKit)
typealias AppDelegateAlias = UIApplicationDelegate
#endif

class AppDelegate: NSObject, AppDelegateAlias {

#if canImport(AppKit)
    func applicationDidFinishLaunching(_ notification: Notification) {
        initializeFirebase()
    }
#elseif canImport(UIKit)
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        initializeFirebase()
        return true
    }
#endif
    
    private func initializeFirebase() {
        guard let plist = self.firebaseProjectConfiguration, let options = FirebaseOptions(contentsOfFile: plist) else {
            logFatal("BOOM!💥 Firebase GoogleService-Info.plist configuration not found.")
        }
        FirebaseApp.configure(options: options)
    }
    
    private var firebaseProjectConfiguration: String? {
        var _firebaseProjectConfiguration: String? = nil
        _firebaseProjectConfiguration = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
        return _firebaseProjectConfiguration
    }
}
