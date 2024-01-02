//
//  TriangleView.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 1/1/24.
//

import SwiftUI

struct TriangleView: View {
    @State var times = 0

    var body: some View {
        Triangle()
            .fill(Color.blue)
            .contentShape(Circle())
            .onTapGesture {
                print("Triangle Tapped: \(times)")
                times += 1
            }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

#Preview {
    TriangleView()
}
