//
//  RunningAppsProvider.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 3/3/26.
//

import SwiftUI

struct RunningAppItem {
    let bundleIdentifier: String
    let displayName: String
    let bundleURL: URL
    let icon: NSImage
    let runningApp: NSRunningApplication
}

class RunningAppsProvider: ObservableObject {
    static let slotCount = 8

    @Published private(set) var displayedSlots: [RunningAppItem?] = Array(repeating: nil, count: RunningAppsProvider.slotCount)

    private var mruBundleIdentifiers: [String] = []
    private var appActivatedObserver: Any?

    init() {
        appActivatedObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                let bundleID = app.bundleIdentifier
            else {
                return
            }

            self?.updateMRU(with: bundleID)
        }
    }

    deinit {
        if let observer = appActivatedObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func refreshSnapshot() {
        let eligibleApps = filteredRunningApps()
        let sortedApps = sortByMRUThenName(eligibleApps)
        let limitedApps = Array(sortedApps.prefix(Self.slotCount))
        displayedSlots = spreadAcrossSlots(limitedApps)
    }

    func appForSlot(_ index: Int) -> RunningAppItem? {
        guard displayedSlots.indices.contains(index) else {
            return nil
        }

        return displayedSlots[index]
    }

    private func filteredRunningApps() -> [RunningAppItem] {
        let runningApps = NSWorkspace.shared.runningApplications
        let ownBundleID = Bundle.main.bundleIdentifier

        return runningApps.compactMap { app in
            guard app.activationPolicy == .regular else {
                return nil
            }

            guard !app.isTerminated else {
                return nil
            }

            guard let bundleURL = app.bundleURL else {
                return nil
            }

            if let ownBundleID, app.bundleIdentifier == ownBundleID {
                return nil
            }

            let bundleID = app.bundleIdentifier ?? bundleURL.absoluteString
            let displayName = app.localizedName ?? bundleURL.deletingPathExtension().lastPathComponent
            let appIcon = NSWorkspace.shared.icon(forFile: bundleURL.path())

            return RunningAppItem(
                bundleIdentifier: bundleID,
                displayName: displayName,
                bundleURL: bundleURL,
                icon: appIcon,
                runningApp: app
            )
        }
    }

    private func sortByMRUThenName(_ apps: [RunningAppItem]) -> [RunningAppItem] {
        let mruIndex: [String: Int] = Dictionary(uniqueKeysWithValues: mruBundleIdentifiers.enumerated().map { ($1, $0) })

        return apps.sorted { left, right in
            let leftIndex = mruIndex[left.bundleIdentifier]
            let rightIndex = mruIndex[right.bundleIdentifier]

            if let leftIndex, let rightIndex {
                return leftIndex < rightIndex
            }

            if leftIndex != nil {
                return true
            }

            if rightIndex != nil {
                return false
            }

            return left.displayName.localizedCaseInsensitiveCompare(right.displayName) == .orderedAscending
        }
    }

    private func spreadAcrossSlots(_ apps: [RunningAppItem]) -> [RunningAppItem?] {
        let slotCount = Self.slotCount
        var slots: [RunningAppItem?] = Array(repeating: nil, count: slotCount)
        let appCount = apps.count

        guard appCount > 0 else {
            return slots
        }

        if appCount == slotCount {
            for index in 0..<slotCount {
                slots[index] = apps[index]
            }
            return slots
        }

        for appIndex in 0..<appCount {
            var slotIndex = Int((Double(appIndex) + 0.5) * Double(slotCount) / Double(appCount)) % slotCount

            while slots[slotIndex] != nil {
                slotIndex = (slotIndex + 1) % slotCount
            }

            slots[slotIndex] = apps[appIndex]
        }

        return slots
    }

    private func updateMRU(with bundleIdentifier: String) {
        mruBundleIdentifiers.removeAll { $0 == bundleIdentifier }
        mruBundleIdentifiers.insert(bundleIdentifier, at: 0)
    }
}
