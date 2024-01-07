//
//  WeaponIcon.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

struct AppIcon: View {
    var icon: NSImage?
    var fallbackSystemImageName: String

    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
            } else {
                Image(systemName: fallbackSystemImageName)
                    .resizable()
            }
        }
    }
}
