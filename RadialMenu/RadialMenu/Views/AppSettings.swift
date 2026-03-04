//
//  AppSettings.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

// MARK: Preliminary information setup
class AppData: ObservableObject {
    static let slotCount = 8
    static let schemaVersionKey = "wheelSchemaVersion"
    static let schemaVersion = 2

    @Published var appPaths: [URL?] {
        didSet {
            normalizeSlotCount()
            saveToUserDefaults()
        }
    }

    init() {
        self.appPaths = Array(repeating: nil, count: Self.slotCount)
        loadFromUserDefaults()
    }

    private func normalizeSlotCount() {
        if appPaths.count > Self.slotCount {
            appPaths = Array(appPaths.prefix(Self.slotCount))
        } else if appPaths.count < Self.slotCount {
            appPaths += Array(repeating: nil, count: Self.slotCount - appPaths.count)
        }
    }

    private func saveToUserDefaults() {
        let pathsAsString = appPaths.map { $0?.absoluteString ?? "" }
        UserDefaults.standard.set(pathsAsString, forKey: "appPaths")
        UserDefaults.standard.set(Self.schemaVersion, forKey: Self.schemaVersionKey)
    }

    private func loadFromUserDefaults() {
        guard let pathsAsString = UserDefaults.standard.array(forKey: "appPaths") as? [String] else {
            return
        }

        let loaded = pathsAsString.map { $0.isEmpty ? nil : URL(string: $0) }
        let storedSchema = UserDefaults.standard.integer(forKey: Self.schemaVersionKey)

        if storedSchema < Self.schemaVersion, loaded.count >= 16 {
            appPaths = migrateLegacySixteenSlotsToEight(loaded)
            saveToUserDefaults()
            return
        }

        if loaded.count >= Self.slotCount {
            appPaths = Array(loaded.prefix(Self.slotCount))
        } else {
            appPaths = loaded + Array(repeating: nil, count: Self.slotCount - loaded.count)
        }
    }

    private func migrateLegacySixteenSlotsToEight(_ loaded: [URL?]) -> [URL?] {
        var migrated = Array(repeating: Optional<URL>.none, count: Self.slotCount)

        for primaryIndex in 0..<4 {
            let oldBase = primaryIndex * 4
            var chosen: [URL] = []

            for offset in 0..<4 {
                guard oldBase + offset < loaded.count, let candidate = loaded[oldBase + offset] else {
                    continue
                }

                if !chosen.contains(candidate) {
                    chosen.append(candidate)
                }

                if chosen.count == 2 {
                    break
                }
            }

            let newBase = primaryIndex * 2
            migrated[newBase] = chosen.indices.contains(0) ? chosen[0] : nil
            migrated[newBase + 1] = chosen.indices.contains(1) ? chosen[1] : nil
        }

        return migrated
    }
}

func fetchAppIcons(appPaths: [URL?]) -> [NSImage?] {
    let workspace = NSWorkspace.shared
    return appPaths.map { path -> NSImage in
        if let path {
            return workspace.icon(forFile: path.path())
        } else {
            return NSImage(systemSymbolName: "plus", accessibilityDescription: "plus image") ?? NSImage()
        }
    }
}

class AppSettings: ObservableObject {
    @Published var isShortcutEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShortcutEnabled, forKey: "isShortcutEnabled")
        }
    }

    @Published var isLiveWindowPreviewEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLiveWindowPreviewEnabled, forKey: "isLiveWindowPreviewEnabled")
        }
    }

    init() {
        isShortcutEnabled = UserDefaults.standard.object(forKey: "isShortcutEnabled") as? Bool ?? true
        isLiveWindowPreviewEnabled = UserDefaults.standard.object(forKey: "isLiveWindowPreviewEnabled") as? Bool ?? false
    }
}

// MARK: - Settings Window View
struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    private enum Tabs: Hashable {
        case general
    }

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 550, height: 400)
        .background(VisualEffectView().ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.async {
                if #available(macOS 14.0, *) {
                    NSApplication.shared.activate()
                } else {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appData: AppData
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Wheel Mapping")
                    .font(.title3.bold())
                Text("Toggle menu: Option + Space\nQuick switch: tap W/A/S/D or arrows\nSubmenu: hold a direction")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Use live window previews (Screen Recording permission required)", isOn: $settings.isLiveWindowPreviewEnabled)
                    .toggleStyle(.switch)

                directionSection(title: "Top (W / ↑)", primary: .top)
                directionSection(title: "Right (D / →)", primary: .right)
                directionSection(title: "Bottom (S / ↓)", primary: .bottom)
                directionSection(title: "Left (A / ←)", primary: .left)

                Button("Clear All Mappings") {
                    appData.appPaths = Array(repeating: nil, count: AppData.slotCount)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private func directionSection(title: String, primary: PrimaryDirection) -> some View {
        let mainIndex = FixedWheelProvider.storageIndex(for: primary, slot: 0)
        let altIndex = FixedWheelProvider.storageIndex(for: primary, slot: 1)

        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            HStack(alignment: .top, spacing: 16) {
                FileDialogPickerView(index: mainIndex, label: "Main")
                    .frame(maxWidth: .infinity, alignment: .leading)
                FileDialogPickerView(index: altIndex, label: "Alternate")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// blur effect
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview {
    SettingsView(settings: AppSettings())
        .environmentObject(sharedAppData)
}
