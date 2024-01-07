//
//  RadialMenuView.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

struct RadialMenuView: View {
    @State private var selectedWeapon: String?
    let hitArea: CGFloat = 135 // Width of the hit area
    let circleRadius: CGFloat = 150 // Length of the hit area
    let radialMenuSections: Int = 8
    
    @EnvironmentObject var appData: AppData
    @ObservedObject var shortcutManager: ShortcutManager

    init(shortcutManager: ShortcutManager) {
        self.shortcutManager = shortcutManager
    }
    
    var body: some View {
                
        ZStack {
            ForEach(0..<appData.appPaths.count, id: \.self) { index in
                Group {
                    Circle()
                        .fill(shortcutManager.hoverStates[index, default: false] ? Color.blue.opacity(1) : Color.white.opacity(0.5))
                        .frame(width: hitArea/1.5)
                        .rotationEffect(Angle(degrees: Double(index) * (360 / Double(appData.appPaths.count)) + 90))
                    
                    // Weapon Icon
                    let appIcon = fetchAppIcons(appPaths: appData.appPaths)[index]
                    AppIcon(icon: appIcon, fallbackSystemImageName: "plus")
                        .padding(appData.appPaths[index] != nil ? 5 : 30) // adjust based on 
                        .frame(width: 90, height: 90) // Adjust size as needed
                        .onHover { isHovering in
                            for item in 0..<appData.appPaths.count
                            {
                                if item == index
                                {
                                    shortcutManager.hoverStates[item] = true
                                }
                                else
                                {
                                    shortcutManager.hoverStates[item] = false
                                }
                            }
                        }
                        .offset(x: self.calculateXOffset(index: index, radius: 0.9), // Offset for icon
                                y: self.calculateYOffset(index: index, radius: 0.9))
                }
                .offset(x: self.calculateXOffset(index: index, radius: 50 + circleRadius / 2), // Change circle radius
                        y: self.calculateYOffset(index: index, radius: 50 + circleRadius / 2)) // Change circle radius
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func calculateXOffset(index: Int, radius: CGFloat) -> CGFloat
    {
        let angle = Double(index) * (2 * .pi / Double(appData.appPaths.count))
        return radius * cos(CGFloat(angle))
    }

    private func calculateYOffset(index: Int, radius: CGFloat) -> CGFloat
    {
        let angle = Double(index) * (2 * .pi / Double(appData.appPaths.count))
        return radius * sin(CGFloat(angle))
    }
}

//#Preview
//{
//    RadialMenuView()
//        .frame(width: 420, height: 420)
//}
