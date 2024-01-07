//
//  AppSettings.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

// MARK: Preliminary information setup
class AppData: ObservableObject {
    @Published var appPaths: [URL?] {
        didSet {
            saveToUserDefaults()
        }
    }
    
    init() {
        self.appPaths = [nil, nil, nil, nil, nil, nil, nil, nil]
        loadFromUserDefaults()
    }
    
    private func saveToUserDefaults() {
        let pathsAsString = appPaths.map { $0?.absoluteString ?? "" }
        UserDefaults.standard.set(pathsAsString, forKey: "appPaths")
    }
    
    private func loadFromUserDefaults() {
        if let pathsAsString = UserDefaults.standard.array(forKey: "appPaths") as? [String] {
            self.appPaths = pathsAsString.map { URL(string: $0) }
        }
    }
}

func fetchAppIcons(appPaths: [URL?]) -> [NSImage] {
    let workspace = NSWorkspace.shared
    return appPaths.map { path -> NSImage in
        if let path = path {
            return workspace.icon(forFile: path.path())  // This always returns NSImage, not NSImage?
        } else {
            // Use the SF Symbol "plus" as a default icon for nil paths
            return NSImage(systemSymbolName: "plus", accessibilityDescription: nil) ?? NSImage()
        }
    }
}

class AppSettings: ObservableObject {
    @Published var isShortcutEnabled: Bool = true
}

// MARK: - Settings Window View
struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 350, height: 400)
        .background(VisualEffectView().ignoresSafeArea())
    }
}

struct GeneralSettingsView: View {

    var body: some View {
        VStack {
            FileDialogPickerView(index: 0)
        }
    }
}

// blur effect
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}

#Preview {
    SettingsView()
}
