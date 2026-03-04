//
//  FixedWheelProvider.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 3/3/26.
//

import SwiftUI
import CoreGraphics
import ScreenCaptureKit

enum PrimaryDirection: String, CaseIterable {
    case top
    case right
    case bottom
    case left

    var title: String {
        switch self {
        case .top: return "Top"
        case .right: return "Right"
        case .bottom: return "Bottom"
        case .left: return "Left"
        }
    }

    var keyHint: String {
        switch self {
        case .top: return "W / ↑"
        case .right: return "D / →"
        case .bottom: return "S / ↓"
        case .left: return "A / ←"
        }
    }
}

enum WheelDisplayPhase: Equatable {
    case root
    case submenu(PrimaryDirection)
}

struct WheelAppItem {
    let appURL: URL
    let bundleIdentifier: String?
    let displayName: String
    let icon: NSImage
    let previewImage: NSImage?
    let isRunning: Bool
}

class WheelUIState: ObservableObject {
    @Published var isVisible = false
    @Published var phase: WheelDisplayPhase = .root
    @Published var highlightedPrimary: PrimaryDirection?
    @Published var highlightedSubmenuSlot: Int?

    func reset() {
        phase = .root
        highlightedPrimary = nil
        highlightedSubmenuSlot = nil
    }
}

@MainActor
class FixedWheelProvider: ObservableObject {
    @Published private(set) var itemsByIndex: [Int: WheelAppItem?] = [:]

    private let appData: AppData
    private let settings: AppSettings

    init(appData: AppData, settings: AppSettings) {
        self.appData = appData
        self.settings = settings
        refreshSnapshot()
    }

    static func storageIndex(for direction: PrimaryDirection, slot: Int) -> Int {
        let primaryIndex: Int
        switch direction {
        case .top: primaryIndex = 0
        case .right: primaryIndex = 1
        case .bottom: primaryIndex = 2
        case .left: primaryIndex = 3
        }
        return (primaryIndex * 2) + slot
    }

    func setPath(_ url: URL?, for direction: PrimaryDirection, slot: Int) {
        let index = Self.storageIndex(for: direction, slot: slot)
        guard appData.appPaths.indices.contains(index) else {
            return
        }

        appData.appPaths[index] = url
    }

    func path(for direction: PrimaryDirection, slot: Int) -> URL? {
        let index = Self.storageIndex(for: direction, slot: slot)
        guard appData.appPaths.indices.contains(index) else {
            return nil
        }

        return appData.appPaths[index]
    }

    func item(for direction: PrimaryDirection, slot: Int) -> WheelAppItem? {
        let index = Self.storageIndex(for: direction, slot: slot)
        return itemsByIndex[index] ?? nil
    }

    func refreshSnapshot() {
        var newItems: [Int: WheelAppItem?] = [:]

        for direction in PrimaryDirection.allCases {
            for slot in 0..<2 {
                let index = Self.storageIndex(for: direction, slot: slot)
                guard appData.appPaths.indices.contains(index), let appURL = appData.appPaths[index] else {
                    newItems[index] = nil
                    continue
                }

                let bundle = Bundle(url: appURL)
                let bundleID = bundle?.bundleIdentifier
                let appName = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? appURL.deletingPathExtension().lastPathComponent
                let icon = NSWorkspace.shared.icon(forFile: appURL.path())
                let runningApp = bundleID.flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0).first { !$0.isTerminated } }

                newItems[index] = WheelAppItem(
                    appURL: appURL,
                    bundleIdentifier: bundleID,
                    displayName: appName,
                    icon: icon,
                    previewImage: nil,
                    isRunning: runningApp != nil
                )

                if settings.isLiveWindowPreviewEnabled, let bundleID, runningApp != nil {
                    loadPreviewImage(bundleIdentifier: bundleID, index: index)
                }
            }
        }

        itemsByIndex = newItems
    }

    func activate(direction: PrimaryDirection, slot: Int) {
        guard let item = item(for: direction, slot: slot) else {
            return
        }

        if let bundleID = item.bundleIdentifier,
           let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first(where: { !$0.isTerminated }),
           runningApp.activate(options: []) {
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: item.appURL, configuration: configuration, completionHandler: nil)
    }

    func promoteToMainIfNeeded(direction: PrimaryDirection, slot: Int) {
        guard slot == 1 else {
            return
        }

        let mainIndex = Self.storageIndex(for: direction, slot: 0)
        let alternateIndex = Self.storageIndex(for: direction, slot: 1)

        guard appData.appPaths.indices.contains(mainIndex), appData.appPaths.indices.contains(alternateIndex) else {
            return
        }

        let currentMain = appData.appPaths[mainIndex]
        appData.appPaths[mainIndex] = appData.appPaths[alternateIndex]
        appData.appPaths[alternateIndex] = currentMain
    }

    private func loadPreviewImage(bundleIdentifier: String, index: Int) {
        guard #available(macOS 14.0, *), settings.isLiveWindowPreviewEnabled, CGPreflightScreenCaptureAccess() else {
            return
        }

        Task { [weak self] in
            guard let self else {
                return
            }

            guard
                let image = try? await Self.captureWindowPreviewImage(bundleIdentifier: bundleIdentifier)
            else {
                return
            }

            guard
                let existing = self.itemsByIndex[index] ?? nil,
                existing.bundleIdentifier == bundleIdentifier,
                self.settings.isLiveWindowPreviewEnabled
            else {
                return
            }

            self.itemsByIndex[index] = WheelAppItem(
                appURL: existing.appURL,
                bundleIdentifier: existing.bundleIdentifier,
                displayName: existing.displayName,
                icon: existing.icon,
                previewImage: image,
                isRunning: existing.isRunning
            )
        }
    }

    @available(macOS 14.0, *)
    private static func captureWindowPreviewImage(bundleIdentifier: String) async throws -> NSImage? {
        let content = try await SCShareableContent.current

        guard
            let window = content.windows.first(where: {
                $0.owningApplication?.bundleIdentifier == bundleIdentifier &&
                $0.windowLayer == 0 &&
                $0.isOnScreen
            })
        else {
            return nil
        }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.width = max(Int(window.frame.width), 320)
        configuration.height = max(Int(window.frame.height), 180)

        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        return NSImage(cgImage: cgImage, size: .zero)
    }
}
