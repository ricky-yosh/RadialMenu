//
//  RadialMenuApp.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 12/28/23.
//

import SwiftUI

@main
struct RadialMenuApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
