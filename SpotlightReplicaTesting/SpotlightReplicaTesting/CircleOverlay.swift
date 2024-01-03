//
//  CircleOverlay.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 1/2/24.
//

import SwiftUI

struct CircleOverlay: View {
    var body: some View {
        // Your underlying view here
        Text("Hello, World!")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray) // Background color for contrast
            .overlay(
                Circle()
                    .fill(Color.blue) // Set the color of the circle
                    .frame(width: 200, height: 200) // Set the size of the circle
                    .opacity(0.5), // Set opacity if you want it semi-transparent
                alignment: .center // Align the circle
            )
    }
}

#Preview {
    CircleOverlay()
}
