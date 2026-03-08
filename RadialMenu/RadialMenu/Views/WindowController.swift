//
//  WindowController.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI
import Carbon.HIToolbox
import QuartzCore

class WindowController: NSWindowController {
    var settings = AppSettings()
    var wheelProvider: FixedWheelProvider
    var uiState: WheelUIState

    private var localKeyDownMonitor: Any?
    private var localKeyUpMonitor: Any?
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var hotKeyHandlerRef: EventHandlerRef?
    private(set) var activeHotKeyLabel: String = "Option + Space"

    private let submenuHoldThreshold: TimeInterval = 0.25
    private let selectionLingerDuration: TimeInterval = 0.15
    private let selectionFadeDuration: TimeInterval = 0.22
    private let selectionFlickerStepDuration: TimeInterval = 0.08
    private let selectionFlickerStepCount = 4
    private var holdTransitionWorkItem: DispatchWorkItem?
    private var selectionWorkItems: [DispatchWorkItem] = []
    private var pendingPrimaryDirection: PrimaryDirection?
    private var pendingPrimaryKeyCode: UInt16?
    private var pendingActivationDirection: PrimaryDirection?
    private var pendingActivationSlot: Int?
    private var isAssignmentInProgress = false
    private var shouldAnimateWheel: Bool {
        settings.forceWheelAnimations || !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    private var selectionFeedbackDuration: TimeInterval {
        selectionLingerDuration + (selectionFlickerStepDuration * Double(selectionFlickerStepCount))
    }

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
        registerLifecycleObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopLocalKeyMonitor()
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        lifecycleObservers.removeAll()
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
    }

    private func registerLifecycleObservers() {
        let appDeactivateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closeMenuIfVisible()
        }
        lifecycleObservers.append(appDeactivateObserver)

        let frontmostAppObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.closeMenuIfFrontmostAppChanged(note)
        }
        lifecycleObservers.append(frontmostAppObserver)

        let spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closeMenuIfVisible()
        }
        lifecycleObservers.append(spaceChangeObserver)

        if let window {
            let windowResignKeyObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.closeMenuIfVisible()
            }
            lifecycleObservers.append(windowResignKeyObserver)
        }
    }

    private func closeMenuIfVisible() {
        guard uiState.isVisible else {
            return
        }
        closeMenu()
    }

    private func closeMenuIfFrontmostAppChanged(_ notification: Notification) {
        guard uiState.isVisible else {
            return
        }

        guard
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let activatedBundleID = app.bundleIdentifier
        else {
            return
        }

        let ownBundleID = Bundle.main.bundleIdentifier
        if activatedBundleID != ownBundleID {
            closeMenu()
        }
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

        if uiState.animationPhase == .selecting || uiState.animationPhase == .closing {
            return nil
        }

        if event.keyCode == 53 { // Escape
            if case .assignment(let direction, let slot) = uiState.displayPhase {
                return handleAssignmentKeyDown(event, direction: direction, slot: slot)
            }
            closeMenu()
            return nil
        }

        if event.isARepeat {
            if case .assignment(let direction, let slot) = uiState.displayPhase {
                return handleAssignmentKeyDown(event, direction: direction, slot: slot)
            }
            return nil
        }

        // Option + Space closes when already open.
        if event.keyCode == 49 && event.modifierFlags.contains(.option) {
            closeMenu()
            return nil
        }

        switch uiState.displayPhase {
        case .root:
            return handleRootKeyDown(event)
        case .submenu(let direction):
            return handleSubmenuKeyDown(event, direction: direction)
        case .assignment(let direction, let slot):
            return handleAssignmentKeyDown(event, direction: direction, slot: slot)
        }
    }

    private func handleLocalKeyUp(_ event: NSEvent) -> NSEvent? {
        guard uiState.isVisible else {
            return event
        }

        guard case .root = uiState.displayPhase else {
            return nil
        }

        guard let direction = mapPrimaryDirection(keyCode: event.keyCode),
              direction == pendingPrimaryDirection,
              event.keyCode == pendingPrimaryKeyCode else {
            return nil
        }

        cancelPendingPrimary()
        uiState.highlightedPrimary = direction
        let selectedMainSlot = wheelProvider.mainSlot(for: direction)
        if wheelProvider.item(for: direction, slot: selectedMainSlot) == nil {
            startSubmenuEntryFeedback(direction: direction)
            return nil
        }

        performStandardSelection(direction: direction, slot: selectedMainSlot)
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
            uiState.displayPhase = .root
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
            performAssignmentFlow(direction: direction, slot: slot)
            return
        }

        wheelProvider.setMainSlot(slot, for: direction)
        wheelProvider.refreshSnapshot()
        performStandardSelection(direction: direction, slot: slot, submenuSlot: slot)
    }

    private func reassignSlotWithoutActivation(direction: PrimaryDirection, slot: Int) {
        performAssignmentFlow(direction: direction, slot: slot)
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
                  self.uiState.displayPhase == .root else {
                return
            }

            self.cancelPendingPrimary()
            self.startSubmenuEntryFeedback(direction: direction)
        }

        holdTransitionWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + submenuHoldThreshold, execute: work)
    }

    private func startSubmenuEntryFeedback(direction: PrimaryDirection) {
        let didStart = startSelectionSequence(
            target: .primary(direction),
            stopLocalMonitoring: false,
            includesFadeOut: false
        ) { [weak self] in
            guard let self else {
                return
            }
            self.uiState.displayPhase = .submenu(direction)
            self.uiState.highlightedPrimary = direction
            self.uiState.highlightedSubmenuSlot = nil
        }

        if !didStart {
            uiState.displayPhase = .submenu(direction)
            uiState.highlightedPrimary = direction
            uiState.highlightedSubmenuSlot = nil
        }
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
        uiState.resetForPresentation()
        fitWindowToActiveScreen()
        showWindow(startLocalMonitoring: true)
    }

    private func closeMenu() {
        stopLocalKeyMonitor()
        cancelPendingPrimary()
        cancelSelectionCloseSequence()
        clearPendingActivation()
        isAssignmentInProgress = false
        uiState.reset()
        uiState.isVisible = false
        window?.orderOut(nil)
    }

    private func showWindow(startLocalMonitoring: Bool) {
        let view = RadialMenuView(wheelProvider: wheelProvider, uiState: uiState, settings: settings)
        window?.contentView = NSHostingView(rootView: view)

        NSApplication.shared.activate()

        window?.orderFrontRegardless()
        window?.makeKey()
        if startLocalMonitoring {
            startLocalKeyMonitor()
        }

        if !shouldAnimateWheel {
            uiState.animationPhase = .idle
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self, self.uiState.isVisible, self.uiState.animationPhase == .opening else {
                    return
                }
                self.uiState.animationPhase = .idle
            }
        }
    }

    private func performAssignmentFlow(direction: PrimaryDirection, slot: Int) {
        guard !isAssignmentInProgress else {
            return
        }
        isAssignmentInProgress = true

        presentAssignmentPicker(direction: direction, slot: slot)
        isAssignmentInProgress = false
    }

    private func presentAssignmentPicker(direction: PrimaryDirection, slot: Int) {
        let candidates = wheelProvider.assignmentCandidates()
        uiState.assignmentCandidates = candidates
        uiState.assignmentQuery = ""
        uiState.assignmentIsLoading = candidates.isEmpty
        refreshAssignmentSelection(direction: direction, slot: slot, preferredSelectionIndex: nil)

        clearPendingActivation()
        uiState.displayPhase = .assignment(direction: direction, slot: slot)
        uiState.highlightedPrimary = direction
        uiState.highlightedSubmenuSlot = slot

        wheelProvider.refreshAssignmentCandidates(force: candidates.isEmpty) { [weak self] loadedCandidates in
            guard let self else {
                return
            }
            guard case .assignment(let activeDirection, let activeSlot) = self.uiState.displayPhase,
                  activeDirection == direction,
                  activeSlot == slot else {
                return
            }

            self.uiState.assignmentCandidates = loadedCandidates
            self.uiState.assignmentIsLoading = false
            self.refreshAssignmentSelection(
                direction: direction,
                slot: slot,
                preferredSelectionIndex: self.uiState.assignmentSelectedIndex
            )
        }
    }

    private func cancelAssignmentMode(direction: PrimaryDirection) {
        uiState.assignmentCandidates = []
        uiState.assignmentSelectedIndex = 0
        uiState.assignmentFilteredIndices = []
        uiState.assignmentQuery = ""
        uiState.assignmentIsLoading = false
        uiState.displayPhase = .submenu(direction)
        uiState.highlightedPrimary = direction
        uiState.highlightedSubmenuSlot = nil
    }

    private func handleAssignmentKeyDown(_ event: NSEvent, direction: PrimaryDirection, slot: Int) -> NSEvent? {
        if event.keyCode == 53 { // Escape
            if uiState.assignmentQuery.isEmpty {
                cancelAssignmentMode(direction: direction)
            } else {
                uiState.assignmentQuery = ""
                uiState.refreshAssignmentFilter(preferredSelectionIndex: uiState.assignmentSelectedIndex)
            }
            return nil
        }

        if event.keyCode == 36 || event.keyCode == 76 { // Return, keypad Enter
            assignSelectedCandidate(direction: direction, slot: slot)
            return nil
        }

        let delta = assignmentNavigationDelta(for: event.keyCode)
        if delta != 0 {
            moveAssignmentSelection(by: delta)
            return nil
        }

        return event
    }

    private func assignmentNavigationDelta(for keyCode: UInt16) -> Int {
        switch keyCode {
        case 126: // Up
            return -1
        case 125: // Down
            return 1
        default:
            return 0
        }
    }

    private func refreshAssignmentSelection(
        direction: PrimaryDirection,
        slot: Int,
        preferredSelectionIndex: Int?
    ) {
        let candidates = uiState.assignmentCandidates
        let currentPath = wheelProvider.path(for: direction, slot: slot)
        let selectedIndexFromPath = currentPath.flatMap { path in
            candidates.firstIndex(where: { $0.appURL.path == path.path })
        }

        let preferred = selectedIndexFromPath ?? preferredSelectionIndex
        uiState.refreshAssignmentFilter(preferredSelectionIndex: preferred)
    }

    private func moveAssignmentSelection(by delta: Int) {
        let filteredIndices = uiState.assignmentFilteredIndices
        guard !filteredIndices.isEmpty else {
            return
        }

        let currentPosition = filteredIndices.firstIndex(of: uiState.assignmentSelectedIndex) ?? 0
        let nextPosition = (currentPosition + delta + filteredIndices.count) % filteredIndices.count
        uiState.assignmentSelectedIndex = filteredIndices[nextPosition]
    }

    private func assignSelectedCandidate(direction: PrimaryDirection, slot: Int) {
        let filteredIndices = uiState.assignmentFilteredIndices
        guard !filteredIndices.isEmpty else {
            cancelAssignmentMode(direction: direction)
            return
        }

        let selectedIndex = filteredIndices.contains(uiState.assignmentSelectedIndex)
            ? uiState.assignmentSelectedIndex
            : filteredIndices[0]
        let selected = uiState.assignmentCandidates[selectedIndex]
        wheelProvider.setPath(selected.appURL, for: direction, slot: slot)
        wheelProvider.setMainSlot(slot, for: direction)
        wheelProvider.refreshSnapshot()

        uiState.assignmentCandidates = []
        uiState.assignmentSelectedIndex = 0
        uiState.assignmentFilteredIndices = []
        uiState.assignmentQuery = ""
        uiState.assignmentIsLoading = false
        uiState.displayPhase = .submenu(direction)
        uiState.highlightedPrimary = direction
        uiState.highlightedSubmenuSlot = slot
    }

    private func performStandardSelection(direction: PrimaryDirection, slot: Int, submenuSlot: Int? = nil) {
        queuePendingActivation(direction: direction, slot: slot)
        let target: SelectionTarget
        if let submenuSlot {
            target = .submenu(direction: direction, slot: submenuSlot)
        } else {
            target = .primary(direction)
        }
        _ = startSelectionSequence(target: target, stopLocalMonitoring: true, includesFadeOut: true) { [weak self] in
            self?.finishSelectionClose()
        }
    }

    @discardableResult
    private func startSelectionSequence(
        target: SelectionTarget,
        stopLocalMonitoring: Bool,
        includesFadeOut: Bool,
        onComplete: @escaping () -> Void
    ) -> Bool {
        guard uiState.isVisible else {
            return false
        }
        guard uiState.animationPhase != .selecting && uiState.animationPhase != .closing else {
            return false
        }

        if stopLocalMonitoring {
            stopLocalKeyMonitor()
        }
        cancelPendingPrimary()
        cancelSelectionCloseSequence()

        applySelectionTarget(target)
        uiState.selectionFX = SelectionFX(
            selectedTarget: target,
            flashCount: 0,
            keepUnselectedPrimaryVisible: !includesFadeOut,
            isDropping: false,
            closeStartedAt: CACurrentMediaTime()
        )
        uiState.animationPhase = .selecting

        scheduleSelectionFlickerSteps()
        scheduleSelectionStep(after: selectionFeedbackDuration) { [weak self] in
            guard let self else {
                return
            }
            if includesFadeOut {
                self.beginSelectionFadeOut(onComplete: onComplete)
                return
            }
            self.cancelSelectionCloseSequence()
            self.uiState.selectionFX = SelectionFX()
            self.uiState.animationPhase = .idle
            onComplete()
        }
        return true
    }

    private func applySelectionTarget(_ target: SelectionTarget) {
        switch target {
        case .primary(let direction):
            uiState.highlightedPrimary = direction
            uiState.highlightedSubmenuSlot = nil
        case .submenu(let direction, let slot):
            uiState.displayPhase = .submenu(direction)
            uiState.highlightedPrimary = direction
            uiState.highlightedSubmenuSlot = slot
        }
    }

    private func beginSelectionFadeOut(onComplete: @escaping () -> Void) {
        uiState.animationPhase = .closing
        uiState.selectionFX.isDropping = false
        scheduleSelectionStep(after: selectionFadeDuration) {
            onComplete()
        }
    }

    private func finishSelectionClose() {
        cancelSelectionCloseSequence()
        let activationDirection = pendingActivationDirection
        let activationSlot = pendingActivationSlot
        clearPendingActivation()
        uiState.reset()
        uiState.isVisible = false
        window?.orderOut(nil)

        if let activationDirection, let activationSlot {
            wheelProvider.activate(direction: activationDirection, slot: activationSlot)
        }
    }

    private func scheduleSelectionStep(after delay: TimeInterval, _ block: @escaping () -> Void) {
        let workItem = DispatchWorkItem(block: block)
        selectionWorkItems.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func scheduleSelectionFlickerSteps() {
        for step in 1...selectionFlickerStepCount {
            let delay = selectionLingerDuration + (selectionFlickerStepDuration * Double(step - 1))
            scheduleSelectionStep(after: delay) { [weak self] in
                self?.uiState.selectionFX.flashCount = step
            }
        }
    }

    private func cancelSelectionCloseSequence() {
        for item in selectionWorkItems {
            item.cancel()
        }
        selectionWorkItems.removeAll()
    }

    private func queuePendingActivation(direction: PrimaryDirection, slot: Int) {
        pendingActivationDirection = direction
        pendingActivationSlot = slot
    }

    private func clearPendingActivation() {
        pendingActivationDirection = nil
        pendingActivationSlot = nil
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
