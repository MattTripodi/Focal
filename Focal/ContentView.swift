//
//  ContentView.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import SwiftUI
import SwiftData
import StoreKit

struct ContentView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @AppStorage("focal.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let reviewPromptSessionCount = 5

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
                checkAndRequestReview()
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

    private func checkAndRequestReview() {
        let key = "focal.lifetimeSessionCount"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)
        if count == reviewPromptSessionCount {
            // Small delay so the prompt doesn't interrupt
            // the phase transition animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                requestReview()
            }
        }
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
