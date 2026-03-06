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
    private var windowController: WindowController?
    private let wheelProvider: FixedWheelProvider
    private let wheelUIState: WheelUIState
    private let settings = AppSettings()

    var body: some Scene {
        MenuBarExtra("Radial Menu App", systemImage: "circle.dashed") {
            AppMenuBarItems(settings: settings)
                .environmentObject(sharedAppData)
        }
        Settings {
            SettingsView(settings: settings)
                .environmentObject(sharedAppData)
        }
        Window("About", id: "about-view") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }

    init() {
        wheelProvider = FixedWheelProvider(appData: sharedAppData)
        wheelUIState = WheelUIState()

        let radialMenuView = RadialMenuView(
            wheelProvider: wheelProvider,
            uiState: wheelUIState,
            settings: settings
        )
        let contentView = NSHostingView(rootView: radialMenuView)
        windowController = WindowController(
            contentView: contentView,
            settings: settings,
            wheelProvider: wheelProvider,
            uiState: wheelUIState
        )
    }
}
