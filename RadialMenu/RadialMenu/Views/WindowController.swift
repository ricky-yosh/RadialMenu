//
//  WindowController.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI
import Carbon.HIToolbox
import UniformTypeIdentifiers

class WindowController: NSWindowController {
    var settings = AppSettings()
    var wheelProvider: FixedWheelProvider
    var uiState: WheelUIState

    private var localKeyDownMonitor: Any?
    private var localKeyUpMonitor: Any?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var hotKeyHandlerRef: EventHandlerRef?
    private(set) var activeHotKeyLabel: String = "Option + Space"

    private let submenuHoldThreshold: TimeInterval = 0.25
    private var holdTransitionWorkItem: DispatchWorkItem?
    private var pendingPrimaryDirection: PrimaryDirection?
    private var pendingPrimaryKeyCode: UInt16?

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    init(contentView: NSView, settings: AppSettings, wheelProvider: FixedWheelProvider, uiState: WheelUIState) {
        self.settings = settings
        self.wheelProvider = wheelProvider
        self.uiState = uiState

        let initialFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let window = NSWindow(
            contentRect: initialFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = contentView
        window.level = .statusBar
        window.ignoresMouseEvents = true

        super.init(window: window)
        registerGlobalToggleHotKey()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopLocalKeyMonitor()
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
    }

    private func registerGlobalToggleHotKey() {
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        let callback: EventHandlerUPP = { _, eventRef, userData in
            guard let userData, let eventRef else {
                return noErr
            }

            var eventHotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &eventHotKeyID
            )

            guard status == noErr else {
                return noErr
            }

            if eventHotKeyID.id == 1 {
                let controller = Unmanaged<WindowController>.fromOpaque(userData).takeUnretainedValue()
                controller.toggleMenu()
            }

            return noErr
        }

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, [eventSpec], userData, &hotKeyHandlerRef)

        let primaryStatus = registerHotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey), id: 1)
        activeHotKeyLabel = primaryStatus == noErr ? "Option + Space" : "Option + Space (registration failed)"
    }

    private func fourCharCode(_ string: String) -> FourCharCode {
        var result: FourCharCode = 0
        for scalar in string.utf16 {
            result = (result << 8) + FourCharCode(scalar)
        }
        return result
    }

    private func registerHotKey(keyCode: UInt32, modifiers: UInt32, id: UInt32) -> OSStatus {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: fourCharCode("RDMN"), id: id)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        if status == noErr, let hotKeyRef {
            hotKeyRefs.append(hotKeyRef)
        }
        return status
    }

    private func startLocalKeyMonitor() {
        if localKeyDownMonitor == nil {
            localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                guard let self else { return event }
                return self.handleLocalKeyDown(event)
            }
        }

        if localKeyUpMonitor == nil {
            localKeyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { [weak self] event in
                guard let self else { return event }
                return self.handleLocalKeyUp(event)
            }
        }
    }

    private func stopLocalKeyMonitor() {
        if let localKeyDownMonitor {
            NSEvent.removeMonitor(localKeyDownMonitor)
            self.localKeyDownMonitor = nil
        }
        if let localKeyUpMonitor {
            NSEvent.removeMonitor(localKeyUpMonitor)
            self.localKeyUpMonitor = nil
        }
    }

    private func handleLocalKeyDown(_ event: NSEvent) -> NSEvent? {
        guard uiState.isVisible else {
            return event
        }

        if event.keyCode == 53 { // Escape
            closeMenu()
            return nil
        }

        // Option + Space closes when already open.
        if event.keyCode == 49 && event.modifierFlags.contains(.option) {
            closeMenu()
            return nil
        }

        if event.isARepeat {
            return nil
        }

        switch uiState.phase {
        case .root:
            return handleRootKeyDown(event)
        case .submenu(let direction):
            return handleSubmenuKeyDown(event, direction: direction)
        }
    }

    private func handleLocalKeyUp(_ event: NSEvent) -> NSEvent? {
        guard uiState.isVisible else {
            return event
        }

        guard case .root = uiState.phase else {
            return nil
        }

        guard let direction = mapPrimaryDirection(keyCode: event.keyCode),
              direction == pendingPrimaryDirection,
              event.keyCode == pendingPrimaryKeyCode else {
            return nil
        }

        cancelPendingPrimary()
        uiState.highlightedPrimary = direction
        wheelProvider.activate(direction: direction, slot: 0)
        closeMenu()
        return nil
    }

    private func handleRootKeyDown(_ event: NSEvent) -> NSEvent? {
        guard let primary = mapPrimaryDirection(keyCode: event.keyCode) else {
            return nil
        }

        pendingPrimaryDirection = primary
        pendingPrimaryKeyCode = event.keyCode
        uiState.highlightedPrimary = primary
        uiState.highlightedSubmenuSlot = nil
        scheduleSubmenuTransition(for: primary, keyCode: event.keyCode)
        return nil
    }

    private func handleSubmenuKeyDown(_ event: NSEvent, direction: PrimaryDirection) -> NSEvent? {
        if isBackNavigationKey(for: direction, keyCode: event.keyCode) {
            uiState.phase = .root
            uiState.highlightedSubmenuSlot = nil
            uiState.highlightedPrimary = nil
            cancelPendingPrimary()
            return nil
        }

        guard let slot = mapSubmenuSlot(for: direction, keyCode: event.keyCode) else {
            return nil
        }

        uiState.highlightedSubmenuSlot = slot

        if event.modifierFlags.contains(.shift) {
            reassignSlotWithoutActivation(direction: direction, slot: slot)
            return nil
        }

        activateOrAssignSlot(direction: direction, slot: slot)
        return nil
    }

    private func activateOrAssignSlot(direction: PrimaryDirection, slot: Int) {
        if wheelProvider.item(for: direction, slot: slot) == nil {
            guard let picked = pickApplicationURL() else {
                return
            }

            wheelProvider.setPath(picked, for: direction, slot: slot)
        }

        wheelProvider.promoteToMainIfNeeded(direction: direction, slot: slot)
        wheelProvider.refreshSnapshot()
        wheelProvider.activate(direction: direction, slot: 0)
        closeMenu()
    }

    private func reassignSlotWithoutActivation(direction: PrimaryDirection, slot: Int) {
        guard let picked = pickApplicationURL() else {
            return
        }

        wheelProvider.setPath(picked, for: direction, slot: slot)
        wheelProvider.refreshSnapshot()
        uiState.phase = .submenu(direction)
        uiState.highlightedPrimary = direction
        uiState.highlightedSubmenuSlot = slot
    }

    private func pickApplicationURL() -> URL? {
        stopLocalKeyMonitor()

        let dialog = NSOpenPanel()
        dialog.title = "Choose an application"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true
        dialog.allowedContentTypes = [.application]
        dialog.canCreateDirectories = false

        let pickedURL = dialog.runModal() == .OK ? dialog.url : nil

        if uiState.isVisible {
            startLocalKeyMonitor()
        }

        return pickedURL
    }

    private func scheduleSubmenuTransition(for direction: PrimaryDirection, keyCode: UInt16) {
        holdTransitionWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            guard self.uiState.isVisible,
                  self.pendingPrimaryDirection == direction,
                  self.pendingPrimaryKeyCode == keyCode,
                  self.uiState.phase == .root else {
                return
            }

            self.uiState.phase = .submenu(direction)
            self.uiState.highlightedPrimary = direction
            self.uiState.highlightedSubmenuSlot = nil
            self.cancelPendingPrimary()
        }

        holdTransitionWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + submenuHoldThreshold, execute: work)
    }

    private func cancelPendingPrimary() {
        holdTransitionWorkItem?.cancel()
        holdTransitionWorkItem = nil
        pendingPrimaryDirection = nil
        pendingPrimaryKeyCode = nil
    }

    private func toggleMenu() {
        guard settings.isShortcutEnabled else {
            return
        }

        if uiState.isVisible {
            closeMenu()
            return
        }

        wheelProvider.refreshSnapshot()
        uiState.reset()
        uiState.isVisible = true
        fitWindowToActiveScreen()
        showWindow()
    }

    private func closeMenu() {
        stopLocalKeyMonitor()
        cancelPendingPrimary()
        uiState.reset()
        uiState.isVisible = false
        window?.orderOut(nil)
    }

    private func showWindow() {
        let view = RadialMenuView(wheelProvider: wheelProvider, uiState: uiState)
        window?.contentView = NSHostingView(rootView: view)

        if #available(macOS 14.0, *) {
            NSApplication.shared.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }

        window?.orderFrontRegardless()
        window?.makeKey()
        startLocalKeyMonitor()
    }

    private func mapPrimaryDirection(keyCode: UInt16) -> PrimaryDirection? {
        switch keyCode {
        case 13, 126: // W, Up
            return .top
        case 2, 124: // D, Right
            return .right
        case 1, 125: // S, Down
            return .bottom
        case 0, 123: // A, Left
            return .left
        default:
            return nil
        }
    }

    private func mapSubmenuSlot(for primary: PrimaryDirection, keyCode: UInt16) -> Int? {
        switch primary {
        case .left, .right:
            if keyCode == 13 || keyCode == 126 { // W, Up
                return 0
            }
            if keyCode == 1 || keyCode == 125 { // S, Down
                return 1
            }
        case .top, .bottom:
            if keyCode == 0 || keyCode == 123 { // A, Left
                return 0
            }
            if keyCode == 2 || keyCode == 124 { // D, Right
                return 1
            }
        }
        return nil
    }

    private func isBackNavigationKey(for primary: PrimaryDirection, keyCode: UInt16) -> Bool {
        switch primary {
        case .top:
            return keyCode == 1 || keyCode == 125 // S, Down
        case .bottom:
            return keyCode == 13 || keyCode == 126 // W, Up
        case .left:
            return keyCode == 2 || keyCode == 124 // D, Right
        case .right:
            return keyCode == 0 || keyCode == 123 // A, Left
        }
    }

    private func fitWindowToActiveScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        guard let screen = targetScreen else {
            return
        }

        window?.setFrame(screen.frame, display: true)
    }
}
