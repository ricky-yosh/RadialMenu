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
    var appData: AppData

    init(appData: AppData)
    {
        self.appData = appData
        let count = self.appData.appPaths.count
        for index in 0..<count
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
