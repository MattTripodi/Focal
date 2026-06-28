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
    @State private var timerService = TimerService()

    var body: some Scene {
        WindowGroup {
            TimerView()
                .environment(timerService)
        }
        .modelContainer(ModelContainer.focal)
    }
}
