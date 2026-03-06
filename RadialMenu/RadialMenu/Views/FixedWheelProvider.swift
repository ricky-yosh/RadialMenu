//
//  FixedWheelProvider.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 3/3/26.
//

import SwiftUI

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
    case assignment(direction: PrimaryDirection, slot: Int)
}

enum WheelAnimationPhase: Equatable {
    case hidden
    case opening
    case idle
    case selecting
    case closing
}

enum SelectionTarget: Equatable {
    case primary(PrimaryDirection)
    case submenu(direction: PrimaryDirection, slot: Int)
}

struct SelectionFX: Equatable {
    var selectedTarget: SelectionTarget?
    var flashCount: Int = 0
    var keepUnselectedPrimaryVisible = false
    var isDropping = false
    var closeStartedAt: CFTimeInterval?
}

struct WheelAppItem {
    let appURL: URL
    let bundleIdentifier: String?
    let displayName: String
    let icon: NSImage
    let isRunning: Bool
}

struct AssignmentCandidate: Identifiable {
    let appURL: URL
    let bundleIdentifier: String?
    let displayName: String
    let icon: NSImage
    let isRunning: Bool

    var id: String {
        bundleIdentifier ?? appURL.path
    }
}

class WheelUIState: ObservableObject {
    @Published var isVisible = false
    @Published var displayPhase: WheelDisplayPhase = .root
    @Published var animationPhase: WheelAnimationPhase = .hidden
    @Published var selectionFX = SelectionFX()
    @Published var highlightedPrimary: PrimaryDirection?
    @Published var highlightedSubmenuSlot: Int?
    @Published var assignmentCandidates: [AssignmentCandidate] = []
    @Published var assignmentSelectedIndex: Int = 0
    @Published var assignmentFilteredIndices: [Int] = []
    @Published var assignmentQuery: String = ""
    @Published var assignmentCursorIndex: Int = 0

    func reset() {
        displayPhase = .root
        animationPhase = .hidden
        selectionFX = SelectionFX()
        highlightedPrimary = nil
        highlightedSubmenuSlot = nil
        assignmentCandidates = []
        assignmentSelectedIndex = 0
        assignmentFilteredIndices = []
        assignmentQuery = ""
        assignmentCursorIndex = 0
    }

    func resetForPresentation() {
        isVisible = true
        displayPhase = .root
        animationPhase = .opening
        selectionFX = SelectionFX()
        highlightedPrimary = nil
        highlightedSubmenuSlot = nil
        assignmentCandidates = []
        assignmentSelectedIndex = 0
        assignmentFilteredIndices = []
        assignmentQuery = ""
        assignmentCursorIndex = 0
    }
}

@MainActor
class FixedWheelProvider: ObservableObject {
    @Published private(set) var itemsByIndex: [Int: WheelAppItem?] = [:]

    private let appData: AppData

    init(appData: AppData) {
        self.appData = appData
        refreshSnapshot()
    }

    static func storageIndex(for direction: PrimaryDirection, slot: Int) -> Int {
        let primaryIndex = directionIndex(for: direction)
        return (primaryIndex * 2) + slot
    }

    static func directionIndex(for direction: PrimaryDirection) -> Int {
        switch direction {
        case .top: return 0
        case .right: return 1
        case .bottom: return 2
        case .left: return 3
        }
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

    func mainSlot(for direction: PrimaryDirection) -> Int {
        let index = Self.directionIndex(for: direction)
        guard appData.mainSlotByDirection.indices.contains(index) else {
            return 0
        }

        let slot = appData.mainSlotByDirection[index]
        return slot == 1 ? 1 : 0
    }

    func setMainSlot(_ slot: Int, for direction: PrimaryDirection) {
        let index = Self.directionIndex(for: direction)
        guard appData.mainSlotByDirection.indices.contains(index) else {
            return
        }

        appData.mainSlotByDirection[index] = slot == 1 ? 1 : 0
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
                    isRunning: runningApp != nil
                )
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

    func assignmentCandidates() -> [AssignmentCandidate] {
        var candidatesByID: [String: AssignmentCandidate] = [:]
        var candidateIdentityByID: [String: String] = [:]
        var runningBundleIDs = Set<String>()
        var runningAppPaths = Set<String>()

        for app in NSWorkspace.shared.runningApplications where !app.isTerminated {
            if let bundleID = app.bundleIdentifier {
                runningBundleIDs.insert(bundleID)
            }
            if let bundleURL = app.bundleURL {
                runningAppPaths.insert(bundleURL.standardizedFileURL.path.lowercased())
            }
        }

        let fileManager = FileManager.default
        for rootURL in assignmentSearchRoots() {
            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isApplicationKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: nil
            ) else {
                continue
            }

            for case let discoveredURL as URL in enumerator {
                guard discoveredURL.pathExtension.lowercased() == "app" else {
                    continue
                }
                let appURL = discoveredURL.standardizedFileURL
                let bundle = Bundle(url: appURL)
                let bundleID = bundle?.bundleIdentifier
                let appName = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? appURL.deletingPathExtension().lastPathComponent

                guard shouldIncludeAssignmentApp(bundle: bundle, appURL: appURL, displayName: appName) else {
                    continue
                }

                let identity = assignmentIdentity(bundleID: bundleID, appURL: appURL)
                if candidateIdentityByID.values.contains(identity) {
                    continue
                }

                let isRunning = bundleID.map { runningBundleIDs.contains($0) }
                    ?? runningAppPaths.contains(appURL.path.lowercased())
                let candidate = AssignmentCandidate(
                    appURL: appURL,
                    bundleIdentifier: bundleID,
                    displayName: appName,
                    icon: NSWorkspace.shared.icon(forFile: appURL.path),
                    isRunning: isRunning
                )
                if candidatesByID[candidate.id] == nil {
                    candidatesByID[candidate.id] = candidate
                    candidateIdentityByID[candidate.id] = identity
                }
            }
        }

        return candidatesByID.values.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    private func assignmentSearchRoots() -> [URL] {
        let fileManager = FileManager.default
        let masks: [FileManager.SearchPathDomainMask] = [.localDomainMask, .systemDomainMask, .userDomainMask]
        var seenPaths = Set<String>()
        var roots: [URL] = []

        for mask in masks {
            for url in fileManager.urls(for: .applicationDirectory, in: mask) {
                let path = url.standardizedFileURL.path.lowercased()
                if seenPaths.insert(path).inserted {
                    roots.append(url)
                }
            }
        }
        return roots
    }

    private func assignmentIdentity(bundleID: String?, appURL: URL) -> String {
        if let bundleID, !bundleID.isEmpty {
            return "bundle:\(bundleID.lowercased())"
        }
        return "path:\(appURL.standardizedFileURL.path.lowercased())"
    }

    private func shouldIncludeAssignmentApp(bundle: Bundle?, appURL: URL, displayName: String) -> Bool {
        if appURL.lastPathComponent.hasSuffix("Helper.app") {
            return false
        }

        if let backgroundOnly = bundle?.object(forInfoDictionaryKey: "LSBackgroundOnly") as? Bool, backgroundOnly {
            return false
        }

        let loweredName = displayName.lowercased()
        if loweredName.hasSuffix(" helper") || loweredName.contains(" login item") {
            return false
        }

        if let bundleID = bundle?.bundleIdentifier?.lowercased(),
           bundleID.contains(".helper") || bundleID.contains(".loginitem") {
            return false
        }

        return true
    }
}
