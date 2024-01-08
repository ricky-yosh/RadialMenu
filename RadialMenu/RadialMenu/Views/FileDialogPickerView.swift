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

    @State private var selectedFile: URL?
    @EnvironmentObject var appData: AppData
    @State private var appPath: URL?

    var body: some View {
        VStack {
            Button("Select File Path: \(index + 1)") {
                self.selectedFile = showOpenFileDialog()
                appData.appPaths[index] = selectedFile
            }
            .buttonStyle(.bordered)
            
            let appIcon = fetchAppIcons(appPaths: [appPath])[0]
            AppIcon(icon: appIcon, fallbackSystemImageName: "plus")
                .frame(width: 60, height: 60)
            Text(appPath?.absoluteString ?? "nil")
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

        dialog.title = "Choose a folder or file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true  // Allow folder selection
        dialog.canCreateDirectories = false

        if dialog.runModal() == .OK {
            return dialog.url // Pathname of the selected item
        } else {
            // User clicked on "Cancel"
            return nil
        }
    }
}


#Preview {
    FileDialogPickerView(index: 1)
        .environmentObject(sharedAppData)
}
