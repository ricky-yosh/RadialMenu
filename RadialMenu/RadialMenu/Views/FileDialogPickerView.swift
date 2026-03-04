//
//  FileDialogPickerView.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/6/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileDialogPickerView: View {
    let index: Int
    var label: String = ""

    @State private var selectedFile: URL?
    @EnvironmentObject var appData: AppData
    @State private var appPath: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.isEmpty ? "Slot \(index + 1)" : label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(appPath == nil ? "Select App" : "Change App") {
                self.selectedFile = showOpenFileDialog()
                appData.appPaths[index] = selectedFile
            }
            .buttonStyle(.bordered)
            
            let appIcon = fetchAppIcons(appPaths: [appPath])[0]
            HStack(spacing: 10) {
                AppIcon(icon: appIcon)
                    .frame(width: 38, height: 38)
                Text(appDisplayName(from: appPath))
                    .font(.caption)
                    .lineLimit(2)
            }
            .help("\(appPath?.absoluteString ?? "nil")")
        }
        .onChange(of: selectedFile) {_, newPath in
            appPath = newPath
        }
        .onChange(of: appData.appPaths[index]) {_,  newPath in
            appPath = newPath
        }
    }

    private func showOpenFileDialog() -> URL? {
        let dialog = NSOpenPanel()

        dialog.title = "Choose an application"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true
        dialog.allowedContentTypes = [.application]
        dialog.canCreateDirectories = false

        if dialog.runModal() == .OK {
            return dialog.url // Pathname of the selected item
        } else {
            // User clicked on "Cancel"
            return nil
        }
    }

    private func appDisplayName(from url: URL?) -> String {
        guard let url else {
            return "Not set"
        }

        let bundle = Bundle(url: url)
        return (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
    }
}


#Preview {
    FileDialogPickerView(index: 1)
        .environmentObject(sharedAppData)
}
