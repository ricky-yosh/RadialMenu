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

func fetchAppIcons(appPaths: [URL?]) -> [NSImage?] {
    let workspace = NSWorkspace.shared
    return appPaths.map { path -> NSImage in
        if let path = path {
            return workspace.icon(forFile: path.path())  // This always returns NSImage, not NSImage?
        } else {
            // Use the SF Symbol "plus" as a default icon for nil paths
            return NSImage(systemSymbolName: "plus", accessibilityDescription: "plus image") ?? NSImage()
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
        .frame(width: 550, height: 400)
        .background(VisualEffectView().ignoresSafeArea())
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appData: AppData
    
    let sectionHeight = 60.0
    let sectionWidth = 150.0
    var body: some View {
        VStack {
            HStack {
                FileDialogPickerView(index: 5)
                    .frame(width: sectionWidth, height: sectionHeight)
                    .padding()
                FileDialogPickerView(index: 6)
                    .frame(width: sectionWidth, height: sectionHeight)
                    .padding()
                FileDialogPickerView(index: 7)
                    .frame(width: sectionWidth, height: sectionHeight)
                    .padding()
            }
            HStack {
                FileDialogPickerView(index: 4)
                    .frame(width: sectionWidth, height: sectionHeight)
                    .padding()
                Button("clear all")
                {
                    appData.appPaths = [nil, nil, nil, nil, nil, nil, nil, nil]
                }
                .background(Color.red) // Background color of the button
                .cornerRadius(4) // Rounded corners
                .frame(width: sectionWidth, height: sectionHeight)
                .padding()
                FileDialogPickerView(index: 0)
                    .frame(width: sectionWidth, height: sectionHeight)
                    .padding()
            }
            
            HStack {
                FileDialogPickerView(index: 3)
                    .frame(width: sectionWidth, height: sectionHeight)
                    .padding()
                FileDialogPickerView(index: 2)
                    .frame(width: sectionWidth, height: sectionHeight)
                    .padding()
                FileDialogPickerView(index: 1)
                    .frame(width: sectionWidth, height: sectionHeight)
                    .padding()
            }
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
        .environmentObject(sharedAppData)
}
