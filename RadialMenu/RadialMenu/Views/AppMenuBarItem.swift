//
//  AppMenuBarItem.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/4/24.
//

import SwiftUI

struct AppMenuBarItem: View
{
    var body: some View
    {
        Button("Quit")
        {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

#Preview
{
    AppMenuBarItem()
}
