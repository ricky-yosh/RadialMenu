//
//  RadialMenuView.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

struct RadialMenuView: View {
    @ObservedObject var wheelProvider: FixedWheelProvider
    @ObservedObject var uiState: WheelUIState
    @ObservedObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let primaryRadialOffset: CGFloat = 130
    private let primaryNodeSize = CGSize(width: 112, height: 112)
    private let submenuCardSize = CGSize(width: 228, height: 132)
    private let submenuCardSpacing: CGFloat = 14
    private let submenuPrimaryPushDistance: CGFloat = 96
    private let submenuPrimaryOpacity: Double = 0.52
    private let wheelFrameSize = CGSize(width: 920, height: 820)
    private let assignmentBackgroundScale: CGFloat = 0.88
    private let assignmentBackgroundOpacity: Double = 0.72
    private let assignmentBackgroundTween: Double = 0.18

    var body: some View {
        ZStack {
            backdropLayer

            ZStack {
                ZStack {
                    ForEach(PrimaryDirection.allCases, id: \.self) { direction in
                        primaryNode(direction)
                            .offset(primaryOffset(for: direction))
                            .offset(mainClusterOffset())
                            .offset(entranceOffset(for: direction))
                            .offset(selectionFadeOffset(for: direction))
                            .opacity(primaryOpacity(for: direction))
                            .animation(.easeOut(duration: 0.16), value: mainClusterAnimationKey)
                    }

                    ForEach(PrimaryDirection.allCases, id: \.self) { direction in
                        submenuCards(for: direction)
                            .opacity(submenuOpacity(for: direction))
                    }
                }
                .scaleEffect(isAssignmentVisible ? assignmentBackgroundScale : 1)
                .opacity(isAssignmentVisible ? assignmentBackgroundOpacity : 1)
                .animation(.easeOut(duration: assignmentBackgroundTween), value: isAssignmentVisible)

                if case .assignment(let direction, _) = uiState.displayPhase {
                    assignmentPicker(direction: direction)
                }
            }
            .frame(width: wheelFrameSize.width, height: wheelFrameSize.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .animation(.easeOut(duration: shouldAnimateWheel ? 0.2 : 0.01), value: uiState.animationPhase)
    }

    private var shouldAnimateWheel: Bool {
        settings.forceWheelAnimations || !reduceMotion
    }

    private var isAssignmentVisible: Bool {
        if case .assignment = uiState.displayPhase {
            return true
        }
        return false
    }

    private func primaryNode(_ direction: PrimaryDirection) -> some View {
        let isSelected = uiState.highlightedPrimary == direction
        let mainSlot = wheelProvider.mainSlot(for: direction)
        let item = wheelProvider.item(for: direction, slot: mainSlot)

        return VStack(spacing: 6) {
            if let icon = item?.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: "plus.app")
                    .font(.system(size: 24, weight: .semibold))
            }

            Text(item?.displayName ?? direction.title)
                .font(.subheadline.bold())
                .lineLimit(1)
            Text(direction.keyHint)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: primaryNodeSize.width, height: primaryNodeSize.height)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.blue.opacity(0.82) : Color.white.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
    }

    @ViewBuilder
    private func submenuCards(for direction: PrimaryDirection) -> some View {
        let hints = submenuHintsForDirection(direction)

        Group {
            if isVerticalSubmenu(for: direction) {
                VStack(spacing: submenuCardSpacing) {
                    submenuCard(direction: direction, slot: 0, keyHint: hints.0)
                    submenuCard(direction: direction, slot: 1, keyHint: hints.1)
                }
            } else {
                HStack(spacing: submenuCardSpacing) {
                    submenuCard(direction: direction, slot: 0, keyHint: hints.0)
                    submenuCard(direction: direction, slot: 1, keyHint: hints.1)
                }
            }
        }
        .offset(submenuOffset(for: direction))
    }

    private func submenuCard(direction: PrimaryDirection, slot: Int, keyHint: String) -> some View {
        let item = wheelProvider.item(for: direction, slot: slot)
        let isHighlighted = uiState.highlightedSubmenuSlot == slot
        let isMainSlot = wheelProvider.mainSlot(for: direction) == slot
        let baseOpacity = item == nil ? 0.88 : 1.0

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(item != nil ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                .overlay(alignment: .center) {
                    if let icon = item?.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.app")
                                .font(.system(size: 24, weight: .semibold))
                            Text("Assign App")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item?.displayName ?? "Empty")
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(keyHint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 9))
            .padding(8)
        }
        .frame(width: submenuCardSize.width, height: submenuCardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHighlighted ? Color.white : (isMainSlot ? Color.blue.opacity(0.95) : Color.white.opacity(0.35)),
                    lineWidth: isHighlighted || isMainSlot ? 2 : 1
                )
        )
        .offset(submenuSelectionFadeOffset(direction: direction, slot: slot))
        .opacity(baseOpacity * submenuCardOpacity(direction: direction, slot: slot))
    }

    private func primaryOffset(for direction: PrimaryDirection) -> CGSize {
        switch direction {
        case .top: return CGSize(width: 0, height: -primaryRadialOffset)
        case .right: return CGSize(width: primaryRadialOffset, height: 0)
        case .bottom: return CGSize(width: 0, height: primaryRadialOffset)
        case .left: return CGSize(width: -primaryRadialOffset, height: 0)
        }
    }

    private func submenuOffset(for direction: PrimaryDirection) -> CGSize {
        let distance = submenuDistance(for: direction)

        switch direction {
        case .top:
            return CGSize(width: 0, height: -distance)
        case .right:
            return CGSize(width: distance, height: 0)
        case .bottom:
            return CGSize(width: 0, height: distance)
        case .left:
            return CGSize(width: -distance, height: 0)
        }
    }

    private func submenuDistance(for direction: PrimaryDirection) -> CGFloat {
        let topBottomCompensation = isVerticalSubmenu(for: direction)
            ? 0
            : (submenuCardSize.width - submenuCardSize.height) / 2

        return primaryRadialOffset + submenuPrimaryPushDistance - topBottomCompensation
    }

    private func isVerticalSubmenu(for direction: PrimaryDirection) -> Bool {
        direction == .left || direction == .right
    }

    private func submenuHintsForDirection(_ direction: PrimaryDirection) -> (String, String) {
        switch direction {
        case .left, .right:
            return ("W / ↑", "S / ↓")
        case .top, .bottom:
            return ("A / ←", "D / →")
        }
    }

    private var mainClusterAnimationKey: String {
        switch uiState.displayPhase {
        case .root:
            return "root"
        case .submenu(let direction):
            return "submenu-\(direction.rawValue)"
        case .assignment(let direction, _):
            return "assignment-\(direction.rawValue)"
        }
    }

    private var backdropLayer: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.95)
            Color.black.opacity(0.28)
        }
        .ignoresSafeArea()
        .opacity(uiState.animationPhase == .hidden ? 0 : 1)
    }

    private func entranceOffset(for direction: PrimaryDirection) -> CGSize {
        guard shouldAnimateWheel, uiState.animationPhase == .opening else {
            return .zero
        }

        switch direction {
        case .top, .right:
            return CGSize(width: 56, height: 0)
        case .left, .bottom:
            return CGSize(width: -56, height: 0)
        }
    }

    private func primaryOpacity(for direction: PrimaryDirection) -> Double {
        if uiState.animationPhase == .opening {
            return 0
        }

        if uiState.animationPhase == .selecting || uiState.animationPhase == .closing {
            if case .primary(let selectedDirection)? = uiState.selectionFX.selectedTarget {
                if selectedDirection == direction {
                    if uiState.animationPhase == .closing {
                        return 0
                    }
                    return flickerOpacity(for: uiState.selectionFX.flashCount)
                }
                if uiState.selectionFX.keepUnselectedPrimaryVisible && uiState.animationPhase == .selecting {
                    return 1
                }
            }
            return 0
        }
        if case .submenu = uiState.displayPhase {
            return submenuPrimaryOpacity
        }
        if case .assignment = uiState.displayPhase {
            return submenuPrimaryOpacity
        }
        return 1
    }

    private func mainClusterOffset() -> CGSize {
        let direction: PrimaryDirection
        switch uiState.displayPhase {
        case .submenu(let activeDirection):
            direction = activeDirection
        case .assignment(let activeDirection, _):
            direction = activeDirection
        case .root:
            return .zero
        }

        switch direction {
        case .top:
            return CGSize(width: 0, height: submenuPrimaryPushDistance)
        case .right:
            return CGSize(width: -submenuPrimaryPushDistance, height: 0)
        case .bottom:
            return CGSize(width: 0, height: -submenuPrimaryPushDistance)
        case .left:
            return CGSize(width: submenuPrimaryPushDistance, height: 0)
        }
    }

    private func selectionFadeOffset(for direction: PrimaryDirection) -> CGSize {
        guard uiState.animationPhase == .closing else {
            return .zero
        }

        guard case .primary(let selectedDirection)? = uiState.selectionFX.selectedTarget,
              selectedDirection == direction else {
            return .zero
        }

        return CGSize(width: 0, height: -28)
    }

    private func submenuOpacity(for direction: PrimaryDirection) -> Double {
        let isVisibleSubmenu: Bool
        switch uiState.displayPhase {
        case .submenu(let activeDirection):
            isVisibleSubmenu = activeDirection == direction
        case .assignment(let activeDirection, _):
            isVisibleSubmenu = activeDirection == direction
        case .root:
            isVisibleSubmenu = false
        }

        if !isVisibleSubmenu {
            return 0
        }

        if uiState.animationPhase == .selecting || uiState.animationPhase == .closing {
            if case .submenu(let selectedDirection, _)? = uiState.selectionFX.selectedTarget,
               selectedDirection == direction {
                return 1
            }
            return 0
        }
        return 1
    }

    private func submenuCardOpacity(direction: PrimaryDirection, slot: Int) -> Double {
        guard uiState.animationPhase == .selecting || uiState.animationPhase == .closing else {
            return 1
        }

        guard case .submenu(let selectedDirection, let selectedSlot)? = uiState.selectionFX.selectedTarget,
              selectedDirection == direction else {
            return 1
        }

        guard selectedSlot == slot else {
            return 0
        }

        if uiState.animationPhase == .closing {
            return 0
        }

        return flickerOpacity(for: uiState.selectionFX.flashCount)
    }

    private func assignmentPicker(direction: PrimaryDirection) -> some View {
        let candidates = uiState.assignmentCandidates
        let filteredIndices = uiState.assignmentFilteredIndices
        let selectedIndex = filteredIndices.contains(uiState.assignmentSelectedIndex)
            ? uiState.assignmentSelectedIndex
            : (filteredIndices.first ?? -1)
        let visibleIndices = visibleAssignmentIndices(
            filteredIndices: filteredIndices,
            selectedCandidateIndex: selectedIndex,
            maxCount: 7
        )
        let query = uiState.assignmentQuery
        let queryCount = query.count
        let cursorIndex = max(0, min(uiState.assignmentCursorIndex, queryCount))
        let cursorStringIndex = query.index(query.startIndex, offsetBy: cursorIndex)
        let leadingQuery = String(query[..<cursorStringIndex])
        let trailingQuery = String(query[cursorStringIndex...])

        return VStack(alignment: .leading, spacing: 10) {
            Text("Assign \(direction.title)")
                .font(.headline)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                if query.isEmpty {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.primary.opacity(0.92))
                            .frame(width: 1, height: 14)
                        Text("Search apps...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    (Text(leadingQuery)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                     + Text("|")
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.92))
                     + Text(trailingQuery)
                        .font(.subheadline)
                        .foregroundStyle(.primary))
                    .lineLimit(1)
                }
                Spacer()
                Text("\(filteredIndices.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            Text("Type to search • \u{2190}/\u{2192} cursor • \u{2191}/\u{2193} move • Enter assign • Esc clear/back")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if candidates.isEmpty {
                Text("No apps found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else if filteredIndices.isEmpty {
                Text("No apps match \"\(uiState.assignmentQuery)\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(visibleIndices, id: \.self) { index in
                    assignmentRow(candidate: candidates[index], isSelected: index == selectedIndex)
                }
            }
        }
        .padding(14)
        .frame(width: 360, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 22, x: 0, y: 12)
    }

    private func assignmentRow(candidate: AssignmentCandidate, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(nsImage: candidate.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.displayName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(candidate.isRunning ? "Running" : "Installed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.white.opacity(0.26) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.white.opacity(0.65) : Color.clear, lineWidth: 1)
        )
    }

    private func visibleAssignmentIndices(filteredIndices: [Int], selectedCandidateIndex: Int, maxCount: Int) -> [Int] {
        guard !filteredIndices.isEmpty else {
            return []
        }

        let selectedWindowIndex = filteredIndices.firstIndex(of: selectedCandidateIndex) ?? 0
        let half = maxCount / 2
        var start = max(0, selectedWindowIndex - half)
        let end = min(filteredIndices.count, start + maxCount)
        if end - start < maxCount {
            start = max(0, end - maxCount)
        }
        return Array(filteredIndices[start..<end])
    }

    private func submenuSelectionFadeOffset(direction: PrimaryDirection, slot: Int) -> CGSize {
        guard uiState.animationPhase == .closing else {
            return .zero
        }

        guard case .submenu(let selectedDirection, let selectedSlot)? = uiState.selectionFX.selectedTarget,
              selectedDirection == direction,
              selectedSlot == slot else {
            return .zero
        }

        return CGSize(width: 0, height: -28)
    }

    private func flickerOpacity(for step: Int) -> Double {
        switch step {
        case 1, 3:
            return 0
        default:
            return 1
        }
    }
}

struct RadialMenuView_Previews: PreviewProvider {
    static var previews: some View {
        let appData = AppData()
        let provider = FixedWheelProvider(appData: appData)
        let uiState = WheelUIState()
        uiState.isVisible = true
        uiState.displayPhase = .submenu(.right)
        uiState.highlightedPrimary = .right
        return RadialMenuView(wheelProvider: provider, uiState: uiState, settings: AppSettings())
    }
}
