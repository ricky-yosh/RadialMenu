//
//  AppMenuBarItem.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

struct AppMenuBarItems: View
{
    @ObservedObject var settings: AppSettings
    @Environment(\.openWindow) var openWindow

    var body: some View
    {
        Toggle(isOn: $settings.isShortcutEnabled) {
            Text("Enable Feature")
        }
        
        Divider()
        
        SettingsLink
        {
            Text("Settings")
        }
        .keyboardShortcut(",", modifiers: .command)
        
        
        Button("Quit")
        {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
        
        Button("About")
        {
            openWindow(id: "about-view")
        }
    }
}

struct AppMenuBarItems_Previews: PreviewProvider {
    static var previews: some View {
        let settings = AppSettings()
        // Initialize SettingsView with the settings instance
        AppMenuBarItems(settings: settings)
            .frame(width: 100.0, height: 100.0)
    }
}
