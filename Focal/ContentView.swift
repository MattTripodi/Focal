//
//  ContentView.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.primary)
        .task {
            // Wire session saving now that we have modelContext
            timerService.onPhaseComplete = { phase in
                let session = FocusSession(
                    duration: timerService.workDuration,
                    phase: phase.rawValue
                )
                modelContext.insert(session)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(TimerService())
        .environment(NotificationManager())
        .environment(AudioManager())
        .modelContainer(ModelContainer.focal)
}
