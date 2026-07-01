//
//  FocalApp.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/12/26.
//

import SwiftUI
import SwiftData

@main
struct FocalApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(env.timerService)
                .environment(env.notificationManager)
                .environment(env.audioManager)
                .task {
                    // Request notification permission on first launch
                    await env.notificationManager.requestPermissionIfNeeded()
                }
        }
        .modelContainer(ModelContainer.focal)
    }
}
