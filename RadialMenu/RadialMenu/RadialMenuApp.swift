//
//  RadialMenuApp.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 12/28/23.
//

import SwiftUI

let sharedAppData = AppData()

@main
struct RadialMenuApp: App {
    var windowController: WindowController?
    var shortcutManager: ShortcutManager
    var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra("Radial Menu App", systemImage: "circle.dashed") {
            AppMenuBarItems(settings: settings)
                .environmentObject(sharedAppData)  // Provide to keep track of app shortcuts
        }
        Settings {
            SettingsView()
                .environmentObject(sharedAppData)  // Provide to keep track of app shortcuts
        }
    }
    
    init()
    {
        self.shortcutManager = ShortcutManager(appData: sharedAppData) // Use the shared instance

        // Create the SwiftUI view with the environment object
//        let shortcutManager = ShortcutManager(appData: sharedAppData)
        let radialMenuView = RadialMenuView(shortcutManager: self.shortcutManager)
            .environmentObject(sharedAppData)

        // Now create the NSHostingView with the radialMenuView
        let contentView = NSHostingView(rootView: radialMenuView)
        windowController = WindowController(contentView: contentView, shortcutManager: shortcutManager, settings: settings, appData: sharedAppData)
    }
}
