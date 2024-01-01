//
//  AppDelegate.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 12/28/23.
//
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { (event) in
            print("Key Down Event Detected")
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command, .option],
               event.keyCode == 35 { // 35 is the key code for 'P'
                print("Command + Option + P Detected")
                DispatchQueue.main.async {
                    self.showOverlay()
                }
            }
        }
    }

    func showOverlay() {
        let overlayView = CircleView()
        let hostingView = NSHostingView(rootView: overlayView)
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)

        window = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Overlay")
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        window.level = .modalPanel
    }
}

struct CircleView: View {
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 100, height: 100)
            .opacity(0.5)
    }
}
