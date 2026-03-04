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
    var wheelProvider: FixedWheelProvider
    var wheelUIState: WheelUIState
    var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra("Radial Menu App", systemImage: "circle.dashed") {
            AppMenuBarItems(settings: settings)
                .environmentObject(sharedAppData)  // Provide to keep track of app shortcuts
        }
        Settings {
            SettingsView(settings: settings)
                .environmentObject(sharedAppData)  // Provide to keep track of app shortcuts
        }
        Window("About", id: "about-view") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
    
    init()
    {
        self.wheelProvider = FixedWheelProvider(appData: sharedAppData, settings: settings)
        self.wheelUIState = WheelUIState()

        // Create the SwiftUI view with the environment object
        let radialMenuView = RadialMenuView(wheelProvider: wheelProvider, uiState: wheelUIState)

        // Now create the NSHostingView with the radialMenuView
        let contentView = NSHostingView(rootView: radialMenuView)
        windowController = WindowController(contentView: contentView, settings: settings, wheelProvider: wheelProvider, uiState: wheelUIState)
    }
}
