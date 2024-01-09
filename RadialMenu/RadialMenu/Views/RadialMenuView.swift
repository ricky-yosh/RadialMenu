//
//  RadialMenuView.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

struct RadialMenuView: View {
    @State private var selectedWeapon: String?
    @State private var isMenuOpen: Bool = false // State to control the animation
    @State private var cancelIsHovered: Bool

    let hitArea: CGFloat = 135 // Width of the hit area
    let circleRadius: CGFloat = 150 // Length of the hit area
    let radialMenuSections: Int = 8
    
    @EnvironmentObject var appData: AppData
    @ObservedObject var shortcutManager: ShortcutManager

    init(shortcutManager: ShortcutManager) {
        self.shortcutManager = shortcutManager
        self.cancelIsHovered = false
    }
    
    var body: some View {
                
        ZStack {
            ForEach(0..<appData.appPaths.count, id: \.self) { index in
                Group {
                    Circle()
                        .fill(shortcutManager.hoverStates[index, default: false] ? Color.blue : Color(red: 0.8, green: 0.8, blue: 0.8))
                        .shadow(color: .black, radius: 10, x: 1, y: 1) // Adding black shadow
                        .scaleEffect(shortcutManager.hoverStates[index, default: false] ? 1.05 : 1.0) // Enlarge when hovering
                        .animation(.easeInOut(duration: 0.03), value: shortcutManager.hoverStates[index, default: false])
                        .frame(width: hitArea/1.5)
                        .rotationEffect(Angle(degrees: Double(index) * (360 / Double(appData.appPaths.count)) + 90))
                    
                    // Weapon Icon
                    let appIcon = fetchAppIcons(appPaths: appData.appPaths)[index]
                    AppIcon(icon: appIcon)
                        .foregroundColor(.white) // Set the image color to black
                        .padding(appData.appPaths[index] != nil ? 5 : 30) // adjust based on icon size
                        .scaleEffect(shortcutManager.hoverStates[index, default: false] ? 1.05 : 1.0) // Enlarge when hovering
                        .animation(.easeInOut(duration: 0.03), value: shortcutManager.hoverStates[index, default: false])
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
                    // Apply the offset and animate
                }
                .offset(x: isMenuOpen ? calculateXOffset(index: index, radius: 50 + circleRadius / 2) : 0,
                        y: isMenuOpen ? calculateYOffset(index: index, radius: 50 + circleRadius / 2) : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.1), value: isMenuOpen)
            }
            ZStack
            {
                Group
                {
                    Circle()
                        .fill(self.cancelIsHovered ? Color(red: 1.0, green: 0.1, blue: 0.1) : Color(red: 1.0, green: 0.4, blue: 0.4))
                        .shadow(color: .black, radius: 15, x: 0.1, y: 0.1) // Adding black shadow
                        .frame(width: hitArea/1.75)
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: hitArea/4, height: hitArea/4)
                        .rotationEffect(.degrees(45))
                }
                .onHover { isHovering in
                    if isHovering
                    {
                        self.cancelIsHovered = true
                        shortcutManager.hoverStatesToNil()
                    }
                    else
                    {
                        self.cancelIsHovered = false
                    }
                }
            }
            
        }
        .frame(width: 500, height: 500)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    isMenuOpen = true // Trigger the animation when the view appears
                }
            }
        }
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

struct RadialMenuView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock AppData and ShortcutManager for the preview
        let appData = AppData()
        let shortcutManager = ShortcutManager(appData: appData) // Assuming ShortcutManager takes AppData

        RadialMenuView(shortcutManager: shortcutManager)
            .environmentObject(appData) // Provide the AppData as an EnvironmentObject
    }
}
