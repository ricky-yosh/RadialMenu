//
//  FullScreenWindow.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 12/29/23.
//

import Cocoa

class FullScreenWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)

        self.level = .floating // Sets the window to float above others
        self.isOpaque = false // Ensures that the window can be transparent
        self.backgroundColor = .clear // Makes the window background transparent
        self.hasShadow = false // Optionally remove shadows
    }
}
