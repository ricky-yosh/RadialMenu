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

    private let primaryOffset: CGFloat = 130

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            ZStack {
                ForEach(PrimaryDirection.allCases, id: \.self) { direction in
                    primaryNode(direction)
                        .offset(primaryOffset(for: direction))
                }

                if case .submenu(let direction) = uiState.phase {
                    submenuCards(for: direction)
                }
            }
            .frame(width: 620, height: 620)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private func primaryNode(_ direction: PrimaryDirection) -> some View {
        let isSelected = uiState.highlightedPrimary == direction
        return VStack(spacing: 6) {
            Text(direction.title)
                .font(.headline)
            Text(direction.keyHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 112, height: 112)
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
                VStack(spacing: 14) {
                    submenuCard(direction: direction, slot: 0, keyHint: hints.0)
                    submenuCard(direction: direction, slot: 1, keyHint: hints.1)
                }
            } else {
                HStack(spacing: 14) {
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

        return ZStack(alignment: .topLeading) {
            if let image = item?.previewImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 228, height: 132)
                    .clipped()
            } else {
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
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(slot == 0 ? "Main" : "Alt")
                    .font(.caption2.bold())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background((slot == 0 ? Color.blue : Color.orange).opacity(0.85), in: Capsule())

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
        .frame(width: 228, height: 132)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.white : Color.white.opacity(0.35), lineWidth: isHighlighted ? 2 : 1)
        )
        .opacity(item == nil ? 0.88 : 1)
    }

    private func primaryOffset(for direction: PrimaryDirection) -> CGSize {
        switch direction {
        case .top: return CGSize(width: 0, height: -primaryOffset)
        case .right: return CGSize(width: primaryOffset, height: 0)
        case .bottom: return CGSize(width: 0, height: primaryOffset)
        case .left: return CGSize(width: -primaryOffset, height: 0)
        }
    }

    private func submenuOffset(for direction: PrimaryDirection) -> CGSize {
        switch direction {
        case .top: return CGSize(width: 0, height: -230)
        case .right: return CGSize(width: 230, height: 0)
        case .bottom: return CGSize(width: 0, height: 230)
        case .left: return CGSize(width: -230, height: 0)
        }
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
}

struct RadialMenuView_Previews: PreviewProvider {
    static var previews: some View {
        let appData = AppData()
        let provider = FixedWheelProvider(appData: appData, settings: AppSettings())
        let uiState = WheelUIState()
        uiState.isVisible = true
        uiState.phase = .submenu(.right)
        uiState.highlightedPrimary = .right
        return RadialMenuView(wheelProvider: provider, uiState: uiState)
    }
}
