//
//  WeaponWheel.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 12/31/23.
//

import SwiftUI

struct WeaponIcon: View {
    var imageName: String

    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .padding(45.0)
            .frame(width: 125, height: 125) // Adjust size as needed
    }
}

struct WeaponWheel: View {
    let weapons = ["airplane", "airplane", "airplane", "airplane", "airplane", "airplane", "airplane", "airplane"]
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
                    Trapezoid(innerWidth: hitAreaWidth * 0.297, outerWidth: hitAreaWidth * 1.2, height: hitAreaLength)
                        .fill(hoverStates[index, default: false] ? Color.red : Color.blue).opacity(0.2)
                        .frame(width: hitAreaWidth * 1.5, height: hitAreaLength)
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
                        .offset(x: self.calculateXOffset(index: index, radius: 10), // Offset for icon
                                y: self.calculateYOffset(index: index, radius: 10))
                }
                .offset(x: self.calculateXOffset(index: index, radius: 50 + hitAreaLength / 2), // Change circle radius
                        y: self.calculateYOffset(index: index, radius: 50 + hitAreaLength / 2)) // Change circle radius
            }
        }
//        .frame(idealWidth: .infinity, idealHeight: .infinity)
    }

    private func calculateXOffset(index: Int, radius: CGFloat) -> CGFloat {
        let angle = Double(index) * (2 * .pi / Double(weapons.count))
        return radius * cos(CGFloat(angle))
    }

    private func calculateYOffset(index: Int, radius: CGFloat) -> CGFloat {
        let angle = Double(index) * (2 * .pi / Double(weapons.count))
        return radius * sin(CGFloat(angle))
    }}

#Preview {
    WeaponWheel()
        .frame(width: 1440, height: 900) // Adjust as needed
}
