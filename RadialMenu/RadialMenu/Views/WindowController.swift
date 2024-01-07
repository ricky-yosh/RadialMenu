//
//  WindowController.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

class WindowController: NSWindowController
{
    var appData: AppData
    var settings = AppSettings()

    private var eventMonitor: Any?
    var shortcutManager: ShortcutManager

    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        // Set the window to appear on the current active space (desktop)
        self.window?.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    }
    
    init(contentView: NSView, shortcutManager: ShortcutManager, settings: AppSettings, appData: AppData)
    {
        self.appData = appData
        self.settings = settings
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

        // Ignores mouse clicks and such
        window.ignoresMouseEvents = true
        
        setupEventMonitor()
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupEventMonitor()
    {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            if event.modifierFlags.contains([.option, .command]) && self!.settings.isShortcutEnabled // shortcut detection
            {
                self?.moveWindowToCursor()
                self?.window?.orderFrontRegardless()
            }
            else
            {
                let hoverStatus: Int? = self?.checkHoverStates(statusArray: (self?.shortcutManager.hoverStates)!)
                // check if it is empty
                if (hoverStatus != nil)
                {
                    let appInfo = self!.appData
                    let chosenAppPath: URL? = appInfo.appPaths[hoverStatus!]
                    if (chosenAppPath != nil)
                    // if it is an application open it
                    {
                        self?.openAppFromPath(appPath: chosenAppPath!.path())
                    }
                }
                
                // clear highlighted point
                self?.shortcutManager.updateHoverStates(active: false)
                self?.window?.orderOut(nil)
            }
        }
    }
    
    // Helper: Opens Application
    private func openAppFromPath(appPath: String)
    {
        let workspace = NSWorkspace.shared
        workspace.open(URL(fileURLWithPath: appPath))
    }
    
    // Helper: checks which application is being hovered
    private func checkHoverStates(statusArray: [Int: Bool]) -> Int?
    {
        var indexHovered: Int? = nil
        for (applicationIndex, hoverStatus) in statusArray
        {
            if hoverStatus
            {
                indexHovered = applicationIndex
                return indexHovered
            }
        }
        return indexHovered
    }

    private func moveWindowToCursor()
    {
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
