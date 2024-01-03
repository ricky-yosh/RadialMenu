//
//  SpotlightReplicaTestingApp.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 12/30/23.
//

import SwiftUI

//@main
struct SpotlightReplicaTestingApp: App {
    @State private var window: NSWindow!

    var body: some Scene {
        WindowGroup {
//            ContentView()
            WeaponWheel2()
                .background {
                    if window == nil {
                        Color.clear.onReceive(NotificationCenter.default.publisher(for:
                                                                                    NSWindow.didBecomeKeyNotification)) { notification in
                            if let window = notification.object as? NSWindow {
                                window.standardWindowButton(.closeButton)?.isHidden = true
                                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                                window.standardWindowButton(.zoomButton)?.isHidden = true
                                
                                window.titlebarAppearsTransparent = true
                                window.styleMask.insert(.fullSizeContentView)
                                window.hasShadow = false
                                
                                // Keep it as an overlay
                                window.level = NSWindow.Level.popUpMenu
                            }
                        }
                    }
                }
                .frame(width: 405.0, height: 405.0)
                .fixedSize()
                .background(TransparentWindow())
                // TODO: DELETE ME
//                .background(TestSlightlyTransparentWindow())
        }
        .windowResizability(.contentSize)
        .windowStyle(HiddenTitleBarWindowStyle())
        MenuBarExtra("Utility App", systemImage: "hammer") {
            AppMenu()
        }
    }
}


struct WeaponWheel2: View {
    
    @State private var selectedWeapon: String?
    let hitAreaWidth: CGFloat = 135 // Width of the hit area
    let hitAreaLength: CGFloat = 150 // Length of the hit area
    @State public var hoverStates: [Int: Bool] = [:]
    
    init() {
        // Initialize all hover states to false
        for index in 0..<weapons.count {
            hoverStates[index] = false
        }
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<weapons.count, id: \.self) { index in
                Group {
                    // Trapezoidal Hit Area
                    Circle()
                        .fill(hoverStates[index, default: false] ? Color.blue.opacity(1) : Color.white.opacity(0.5))
                        .frame(width: hitAreaWidth/1.5)
                        .rotationEffect(Angle(degrees: Double(index) * (360 / Double(weapons.count)) + 90))
                    
                    // Weapon Icon
                    WeaponIcon(imageName: weapons[index])
                        .onTapGesture(perform: {
                            print("\(index) clicked")
                        })
                        .onHover { isHovering in
                            for item in 0..<weapons.count
                            {
                                if item == index
                                {
                                    hoverStates[item] = true
                                }
                                else
                                {
                                    hoverStates[item] = false
                                }
                            }
                        }
                        .offset(x: self.calculateXOffset(index: index, radius: 0.9), // Offset for icon
                                y: self.calculateYOffset(index: index, radius: 0.9))
                }
                .offset(x: self.calculateXOffset(index: index, radius: 50 + hitAreaLength / 2), // Change circle radius
                        y: self.calculateYOffset(index: index, radius: 50 + hitAreaLength / 2)) // Change circle radius
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func calculateXOffset(index: Int, radius: CGFloat) -> CGFloat {
        let angle = Double(index) * (2 * .pi / Double(weapons.count))
        return radius * cos(CGFloat(angle))
    }

    private func calculateYOffset(index: Int, radius: CGFloat) -> CGFloat {
        let angle = Double(index) * (2 * .pi / Double(weapons.count))
        return radius * sin(CGFloat(angle))
    }
    
}

    #Preview {
        WeaponWheel2()
            .frame(width: 420, height: 420) // Adjust as needed
    }
