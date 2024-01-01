//
//  ContentView.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 12/30/23.
//

import SwiftUI

//struct ContentView: View {
//    
//    var body: some View {
//        VStack {
//            Circle()
//                .inset(by: 200 / 2) // Assuming a lineWidth of 5
//                .stroke(
//                    Color.cyan.opacity(0.5),
//                    lineWidth: 200.0
//                )
//        }
//        .padding(.bottom, 25.0)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}

struct ContentView: View {
    var body: some View {
        ZStack {
            PieSegmentView(index: 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            PieSegmentView(index: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            PieSegmentView(index: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            PieSegmentView(index: 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            PieSegmentView(index: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            PieSegmentView(index: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            PieSegmentView(index: 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            PieSegmentView(index: 7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .rotationEffect(.degrees(22.5)) // Rotating the entire pie chart
        .padding(.bottom, 30.0)
    }
}

struct PieSegmentView: View {
    let index: Int
    let gapSize: CGFloat = 10 // Increased gap size for clearer separation

    var body: some View {
        PieSegment(startAngle: .degrees(Double(index) * 45), endAngle: .degrees(Double(index + 1) * 45))
            .fill(Color.random)
            .offset(x: offset.width, y: offset.height)
            // Add hover effect or other modifiers here
    }

    var offset: CGSize {
        let angle = Double(index) * 45 + 22.5
        let radian = angle * Double.pi / 180
        return CGSize(width: CGFloat(cos(radian)) * gapSize, height: CGFloat(sin(radian)) * gapSize)
    }
}

struct PieSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()

        return path
    }
}

extension Color {
    static var random: Color {
        return Color(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1))
    }
}

// Background

class TransparentWindowView: NSView {
  override func viewDidMoveToWindow() {
    window?.backgroundColor = .clear
    super.viewDidMoveToWindow()
  }
}

struct TransparentWindow: NSViewRepresentable {
    func makeNSView(context: Self.Context) -> NSView { return TransparentWindowView() }
    func updateNSView(_ nsView: NSView, context: Context) { }
}

// TODO: DELETE ME
class TestSlightlyTransparentWindowView: NSView {
  override func viewDidMoveToWindow() {
      window?.backgroundColor = NSColor.green.withAlphaComponent(0.3)
    super.viewDidMoveToWindow()
  }
}

struct TestSlightlyTransparentWindow: NSViewRepresentable {
    func makeNSView(context: Self.Context) -> NSView { return TestSlightlyTransparentWindowView() }
    func updateNSView(_ nsView: NSView, context: Context) { }
}

// TODO: END OF TEST CONTENT

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
