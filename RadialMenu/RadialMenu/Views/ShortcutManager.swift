//
//  ShortcutManager.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

class ShortcutManager: ObservableObject
{
    @Published var hoverStates: [Int: Bool] = [:]
    private let slotCount = RunningAppsProvider.slotCount

    init()
    {
        hoverStatesToNil()
    }
    
    func hoverStatesToNil()
    {
        for index in 0..<slotCount
        {
            hoverStates[index] = false
        }
    }

    func updateHoverStates(active: Bool)
    {
        for index in 0..<hoverStates.count
        {
            hoverStates[index] = active
        }
    }
}
