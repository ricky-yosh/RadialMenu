//
//  WeaponIcon.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

struct AppIcon: View {
    var icon: NSImage?

    var body: some View {
        if self.icon?.accessibilityDescription == "plus image"
        {
            Image(nsImage: icon!)
                .resizable()
        }
        else
        {
            Image(nsImage: icon!)
                .resizable()
                .padding(8.0) // make image icon smaller
        }
    }
}
