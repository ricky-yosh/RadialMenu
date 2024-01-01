//
//  AppMenu.swift
//  SpotlightReplicaTesting
//
//  Created by Ricky Yoshioka on 12/30/23.
//

import SwiftUI

struct AppMenu: View {
    var body: some View {
        Button("Quit")
        {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

struct AppMenu_Previews: PreviewProvider {
    static var previews: some View {
        AppMenu()
    }
}
