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
    @AppStorage("focal.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabs
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .task {
            timerService.onPhaseComplete = { phase in
                let session = FocusSession(
                    duration: timerService.workDuration,
                    phase: phase.rawValue
                )
                modelContext.insert(session)
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.primary)
    }
}

#Preview {
    ContentView()
        .environment(TimerService())
        .environment(NotificationManager())
        .environment(AudioManager())
        .environment(StoreManager())
        .modelContainer(ModelContainer.focal)
}
