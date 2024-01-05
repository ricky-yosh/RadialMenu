//
//  AppleScriptTests.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 1/4/24.
//
import SwiftUI
import AppKit

struct AppleScriptTestsApp: App {
    var body: some Scene {
        WindowGroup {
            AppleScriptTestsView()
        }
    }
}

struct AppleScriptTestsView: View {
    var body: some View {
        Button("Open Safari") {
            runAppleScriptToOpenSafari()
        }
    }

    func runAppleScriptToOpenSafari() {
        let workspace = NSWorkspace.shared
        let appPath = "/Applications/Obsidian.app"  // Replace with the path of the selected app
        workspace.open(URL(fileURLWithPath: appPath))
    }
}
