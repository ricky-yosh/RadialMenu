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

    var body: some View
    {
        Toggle(isOn: $settings.isShortcutEnabled) {
            Text("Enable Feature")
        }
        
        Divider()
        
        Button("Quit")
        {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

struct AppMenuBarItems_Previews: PreviewProvider {
    static var previews: some View {
        let settings = AppSettings()
        // Initialize SettingsView with the settings instance
        AppMenuBarItems(settings: settings)
    }
}
