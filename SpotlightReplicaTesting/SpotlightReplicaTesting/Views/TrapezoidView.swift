//
//  TrapezoidView.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 12/31/23.
//

import SwiftUI

struct TrapezoidView: View {
    let weapons = ["airplane", "airplane", "airplane", "airplane", "airplane", "airplane", "airplane", "airplane"]
    let hitAreaWidth: CGFloat = 185 // Width of the hit area
    let hitAreaLength: CGFloat = 400 // Length of the hit area
    @State private var hoverStates: [Int: Bool] = [:]
    let index = 1
    
    var body: some View {
        Trapezoid(innerWidth: hitAreaWidth * 0.22, outerWidth: hitAreaWidth * 2, height: hitAreaLength)
            .fill(hoverStates[index, default: false] ? Color.red : Color.red).opacity(0.2)
            .frame(width: hitAreaWidth * 1.5, height: hitAreaLength)
            .contentShape(Circle()) // <-- Use contentShape here
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
}

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
    TrapezoidView()
}
