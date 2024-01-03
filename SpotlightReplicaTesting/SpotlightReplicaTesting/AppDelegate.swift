//
//  AppDelegate.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 1/2/24.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("HHello")
        // Create the SwiftUI view that provides the window contents.
        let weaponWheelView = WeaponWheel()

        // Create the transparent window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: weaponWheelView)
        window.makeKeyAndOrderFront(nil)

        // Set the window to be transparent and always on top
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.level = .floating
    }
}
