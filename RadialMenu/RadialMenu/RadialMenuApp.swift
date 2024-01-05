//
//  RadialMenuApp.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 12/28/23.
//

import SwiftUI

@main
struct RadialMenuApp: App {
    var windowController: WindowController?
    var shortcutManager: ShortcutManager
    
    var body: some Scene {
        MenuBarExtra("Radial Menu App", systemImage: "circle.dashed") {
            AppMenuBarItem()
        }
    }
    
    init()
    {
        // Initialize the ShortcutManager with the appropriate count
        self.shortcutManager = ShortcutManager(count: appPaths.count)

        // Pass the ShortcutManager instance to the WindowController
        let contentView = NSHostingView(rootView: RadialMenuView(shortcutManager: shortcutManager))
        windowController = WindowController(contentView: contentView, shortcutManager: shortcutManager)
    }
}
