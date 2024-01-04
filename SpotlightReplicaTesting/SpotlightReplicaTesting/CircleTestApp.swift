//
//  App.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 1/2/24.
//

import SwiftUI
import AppKit

@main
struct CircleOverlayTest: App {
    var windowController: WindowController?
    var shortcutManager: ShortcutManager

    var body: some Scene {
        MenuBarExtra("Utility App", systemImage: "hammer") {
            AppMenu()
        }
    }

//    init() {
//        let contentView = WeaponWheel2() // Your SwiftUI circle view
//
//        // Adjust the size of the window here
//        let windowSize = CGSize(width: 500, height: 500)
//        let window = NSWindow(
//            contentRect: NSRect(origin: .zero, size: windowSize),
//            styleMask: [.borderless],
//            backing: .buffered, defer: false)
//        window.center()
//        window.isOpaque = false
//        window.backgroundColor = NSColor.clear
//        window.contentView = NSHostingView(rootView: contentView)
//        window.makeKeyAndOrderFront(nil)
//    }
    
    init() {
        // Initialize the ShortcutManager with the appropriate count
        self.shortcutManager = ShortcutManager(count: weapons.count)

        // Pass the ShortcutManager instance to the WindowController
        let contentView = NSHostingView(rootView: WeaponWheel2(shortcutManager: shortcutManager))
        windowController = WindowController(contentView: contentView, shortcutManager: shortcutManager)
    }
}

struct CircleView: View {
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 200, height: 200)
            .background(Color.clear)
    }
}

class WindowController: NSWindowController {
    private var eventMonitor: Any?
    var shortcutManager: ShortcutManager

    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Set the window to appear on the current active space (desktop)
        self.window?.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    }
    
    init(contentView: NSView, shortcutManager: ShortcutManager)
    {
        self.shortcutManager = shortcutManager
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.borderless],
            backing: .buffered, defer: false)
        window.center()
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.contentView = contentView

        super.init(window: window)

        setupEventMonitor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            if event.modifierFlags.contains([.option, .command])
            {
                self?.moveWindowToCursor()
                self?.window?.orderFrontRegardless()
            }
            else
            {
                self?.shortcutManager.updateHoverStates(active: false)
                self?.window?.orderOut(nil)
            }
        }
    }

    private func moveWindowToCursor() {
        // Ensure the window appears on the current active space (desktop)
        self.window?.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            let windowSize = self.window?.frame.size ?? CGSize.zero
            var newOriginX = mouseLocation.x - windowSize.width / 2
            // Add safe area x-acis
            if (newOriginX > (screenRect.maxX - windowSize.width))
            {
                newOriginX = screenRect.maxX - windowSize.width
            }
            else if (newOriginX < screenRect.minX)
            {
                newOriginX = screenRect.minX
            }
            var newOriginY = mouseLocation.y - windowSize.height / 2
            // Add safe area y-axis
            if (newOriginY > (screenRect.maxY - windowSize.height))
            {
                newOriginY = screenRect.maxY - windowSize.height
            }
            else if (newOriginY < screenRect.minY)
            {
                newOriginY = screenRect.minY
            }
            let newOrigin = CGPoint(x: newOriginX,
                                    y: newOriginY)
            self.window?.setFrameOrigin(newOrigin)
        }
    }
}
