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
            .frame(width: 30, height: 30) // Adjust size as needed
    }
}

struct WeaponWheel: View {
    let weapons = ["airplane", "airplane", "airplane", "airplane", "airplane", "airplane", "airplane", "airplane"]
    @State private var selectedWeapon: String?
    let hitAreaWidth: CGFloat = 185 // Width of the hit area
    let hitAreaLength: CGFloat = 400 // Length of the hit area
    @State private var hoverStates: [Int: Bool] = [:]

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
                    // Weapon Icon
                    WeaponIcon(imageName: weapons[index])
                        .offset(x: self.calculateXOffset(index: index, radius: 10), // Offset for icon
                                y: self.calculateYOffset(index: index, radius: 10))

                    // Trapezoidal Hit Area
                    Trapezoid(innerWidth: hitAreaWidth * 0.22, outerWidth: hitAreaWidth * 2, height: hitAreaLength)
                        .fill(hoverStates[index, default: false] ? Color.red : Color.clear).opacity(0.2)
                        .frame(width: hitAreaWidth * 1.5, height: hitAreaLength)
                        .contentShape(Trapezoid(innerWidth: hitAreaWidth * 0.67, outerWidth: hitAreaWidth * 2, height: hitAreaLength)) // <-- Use contentShape here
                        .rotationEffect(Angle(degrees: Double(index) * (360 / Double(weapons.count)) + 90))
                        .onHover { isHovering in
                            for item in 0..<weapons.count
                            {
                                if item == index
                                {
                                    hoverStates[item] = isHovering
                                }
                                else
                                {
                                    hoverStates[item] = false
                                }
                            }
                        }
                }
                .offset(x: self.calculateXOffset(index: index, radius: 50 + hitAreaLength / 2), // Offset for the entire group
                        y: self.calculateYOffset(index: index, radius: 50 + hitAreaLength / 2))
            }
        }
        .frame(idealWidth: .infinity, idealHeight: .infinity)
    }

    private func calculateXOffset(index: Int, radius: CGFloat) -> CGFloat {
        let angle = Double(index) * (2 * .pi / Double(weapons.count))
        return radius * cos(CGFloat(angle))
    }

    private func calculateYOffset(index: Int, radius: CGFloat) -> CGFloat {
        let angle = Double(index) * (2 * .pi / Double(weapons.count))
        return radius * sin(CGFloat(angle))
    }}

struct Trapezoid: Shape {
    var innerWidth: CGFloat
    var outerWidth: CGFloat
    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate the difference based on the frame of the shape, not the rect
        _ = (outerWidth - innerWidth) / 2
        let rectHeight = rect.height
        
        // Points for the trapezoid
        let topLeading = CGPoint(x: rect.midX - innerWidth / 2, y: rectHeight)
        let topTrailing = CGPoint(x: rect.midX + innerWidth / 2, y: rectHeight)
        let bottomLeading = CGPoint(x: rect.midX - outerWidth / 2, y: 0)
        let bottomTrailing = CGPoint(x: rect.midX + outerWidth / 2, y: 0)
        
        path.move(to: bottomLeading)
        path.addLine(to: topLeading)
        path.addLine(to: topTrailing)
        path.addLine(to: bottomTrailing)
        path.closeSubpath()
        
        return path
    }
}


#Preview {
    WeaponWheel()
        .frame(width: 1440, height: 900) // Adjust as needed
}
