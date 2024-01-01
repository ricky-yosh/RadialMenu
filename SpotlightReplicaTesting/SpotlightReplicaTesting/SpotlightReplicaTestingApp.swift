//
//  SpotlightReplicaTestingApp.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 12/30/23.
//

import SwiftUI

@main
struct SpotlightReplicaTestingApp: App {
    @State private var window: NSWindow!

    var body: some Scene {
        WindowGroup {
//            ContentView()
            WeaponWheel()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if window == nil {
                        Color.clear.onReceive(NotificationCenter.default.publisher(for:
                                                                                    NSWindow.didBecomeKeyNotification)) { notification in
                            if let window = notification.object as? NSWindow {
                                window.standardWindowButton(.closeButton)?.isHidden = true
                                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                                window.standardWindowButton(.zoomButton)?.isHidden = true
                                
                                // Keep it as an overlay
                                window.level = NSWindow.Level.popUpMenu
                            }
                        }
                    }
                }
//                .background(TransparentWindow())
                // TODO: DELETE ME
                .background(TestSlightlyTransparentWindow())
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        MenuBarExtra("Utility App", systemImage: "hammer") {
            AppMenu()
        }
    }
}
