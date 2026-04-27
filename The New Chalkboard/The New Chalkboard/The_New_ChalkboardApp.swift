//
//  The_New_ChalkboardApp.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/17/24.
//

import SwiftUI

@main
struct The_New_ChalkboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Global accent used by controls + SF Symbol rendering across the app.
                .tint(.appAccent)
        }
    }
}
