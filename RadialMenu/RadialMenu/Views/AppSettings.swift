//
//  AppSettings.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

// MARK: Preliminary information setup
var appPaths: [String?] = [nil, nil, nil, nil, nil, nil, nil, nil]

func fetchAppIcons(appPaths: [String?]) -> [NSImage] {
    let workspace = NSWorkspace.shared
    return appPaths.map { path -> NSImage in
        if let path = path {
            return workspace.icon(forFile: path)  // This always returns NSImage, not NSImage?
        } else {
            // Use the SF Symbol "plus" as a default icon for nil paths
            return NSImage(systemSymbolName: "plus", accessibilityDescription: nil) ?? NSImage()
        }
    }
}

let appPathIcons = fetchAppIcons(appPaths: appPaths)

class AppSettings: ObservableObject {
    @Published var isShortcutEnabled: Bool = false
}

// MARK: - Settings Window View
struct SettingsView: View {
    var body: some View {
        Text("Settings Window!")
            .frame(width: 300, height: 200)
    }
}

func openSettingsWindow() {
    let newWindow = NSWindow(
        contentRect: NSRect(x: 20, y: 20, width: 300, height: 200),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered, defer: false)
    newWindow.center()
    newWindow.setFrameAutosaveName("New Window")
    newWindow.contentView = NSHostingView(rootView: SettingsView())
    newWindow.makeKeyAndOrderFront(nil)
}
