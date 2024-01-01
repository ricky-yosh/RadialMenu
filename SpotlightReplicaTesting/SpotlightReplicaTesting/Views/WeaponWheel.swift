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
    let hitAreaWidth: CGFloat = 100 // Width of the hit area
    let hitAreaLength: CGFloat = 400 // Length of the hit area

    var body: some View {
        ZStack {
            ForEach(0..<weapons.count, id: \.self) { index in
                Group {
                    // Weapon Icon
                    WeaponIcon(imageName: weapons[index])
                        .offset(x: self.calculateXOffset(index: index, radius: 10), // Offset for icon
                                y: self.calculateYOffset(index: index, radius: 10))

                    // Trapezoidal Hit Area
                    Trapezoid(innerWidth: hitAreaWidth, outerWidth: hitAreaWidth * 1.5, height: hitAreaLength)
                        .fill(Color.red).opacity(0.2)
                        .frame(width: hitAreaWidth * 1.5, height: hitAreaLength)
                        .rotationEffect(Angle(degrees: Double(index) * (360 / Double(weapons.count)) + 270))
                        .onTapGesture {
                            self.selectedWeapon = self.weapons[index]
                        }
                }
                .offset(x: self.calculateXOffset(index: index, radius: 50 + hitAreaLength / 2), // Offset for the entire group
                        y: self.calculateYOffset(index: index, radius: 50 + hitAreaLength / 2))
            }
        }
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

        let difference = (outerWidth - innerWidth) / 2
        let topLeading = CGPoint(x: difference, y: 0)
        let topTrailing = CGPoint(x: rect.width - difference, y: 0)
        let bottomLeading = CGPoint(x: 0, y: rect.height)
        let bottomTrailing = CGPoint(x: rect.width, y: rect.height)

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
        .frame(width: 1000, height: 1000) // Adjust as needed
}
