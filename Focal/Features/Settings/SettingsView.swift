//
//  SettingsView.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(AudioManager.self) private var audio
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var modelContext
    @State private var showingSoundPicker = false
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                timerSection
                behaviorSection
                soundSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingSoundPicker) {
            SoundPickerSheet(audio: audio, isPremium: store.isPremium) {
                showingSoundPicker = false
                showingPaywall = true
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environment(store)
        }
    }
    
    // MARK: - Timer Durations (Premium)
    
    private var timerSection: some View {
        Section {
            DurationRow(
                label: "Work",
                minutes: Int(timerService.workDuration / 60),
                isPremium: store.isPremium
            ) { minutes in
                timerService.workDuration = TimeInterval(minutes * 60)
            } onLocked: {
                showingPaywall = true
            }
            
            DurationRow(
                label: "Short Break",
                minutes: Int(timerService.shortBreakDuration / 60),
                isPremium: store.isPremium
            ) { minutes in
                timerService.shortBreakDuration = TimeInterval(minutes * 60)
            } onLocked: {
                showingPaywall = true
            }
            
            DurationRow(
                label: "Long Break",
                minutes: Int(timerService.longBreakDuration / 60),
                isPremium: store.isPremium
            ) { minutes in
                timerService.longBreakDuration = TimeInterval(minutes * 60)
            } onLocked: {
                showingPaywall = true
            }
            
            //sessions per cycle row
            SessionsPerCycleRow(
                value: timerService.sessionsPerCycle,
                isPremium: store.isPremium
            ) { count in
                timerService.sessionsPerCycle = count
            } onLocked: {
                showingPaywall = true
            }
            
        } header: {
            Text("Timer Durations")
        } footer: {
            if !store.isPremium {
                Text("Custom durations and session counts are available with Focal Premium.")
            } else {
                Text("Sessions per cycle determines how many focus sessions before a long break.")
            }
        }
    }
    
    
    // MARK: - Behavior (Premium)
    
    private var behaviorSection: some View {
        Section("Behavior") {
            if store.isPremium {
                Toggle(isOn: Binding(
                    get: { timerService.autoStartNextSession },
                    set: { timerService.autoStartNextSession = $0 }
                )) {
                    Text("Auto-start next session")
                }
            } else {
                Button(action: { showingPaywall = true }) {
                    HStack {
                        Text("Auto-start next session")
                            .foregroundStyle(.primary)
                        Spacer()
                        ProBadge()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - Sound
    
    private var soundSection: some View {
        Section("Sound") {
            Button {
                showingSoundPicker = true
            } label: {
                HStack {
                    Label(audio.currentSound.rawValue, systemImage: audio.currentSound.systemImage)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // MARK: - About
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
                
#if DEBUG
                Button("Reset Premium (Debug)") {
                    Task { await store.restorePurchases() }
                }
                .foregroundStyle(.red)
                
                Button("Seed Stats (Debug)") {
                    seedStatsData()
                }
                .foregroundStyle(.blue)
#endif
            }
        }
    }
    
#if DEBUG
    private func seedStatsData() {
        let calendar = Calendar.current
        let durations: [TimeInterval] = [
            25 * 60, 25 * 60, 25 * 60,  // today — 3 sessions
            25 * 60, 25 * 60,            // yesterday — 2 sessions
            25 * 60, 25 * 60, 25 * 60,  // 2 days ago — 3 sessions
            25 * 60,                      // 3 days ago — 1 session
            25 * 60, 25 * 60,            // 4 days ago — 2 sessions
        ]
        
        let offsets = [0, 0, 0, -1, -1, -2, -2, -2, -3, -4, -4]
        
        for (i, duration) in durations.enumerated() {
            let date = calendar.date(
                byAdding: .day,
                value: offsets[i],
                to: calendar.startOfDay(for: .now).addingTimeInterval(12 * 3600)
            ) ?? .now
            
            let session = FocusSession(
                startDate: date,
                duration: duration,
                phase: "Focus",
                completed: true
            )
            modelContext.insert(session)
        }
    }
#endif
    
}

// MARK: - Subviews

private struct DurationRow: View {
    let label: String
    let minutes: Int
    let isPremium: Bool
    let onChanged: (Int) -> Void
    let onLocked: () -> Void
    
    var body: some View {
        if isPremium {
            HStack {
                Text(label)
                Spacer()
                Stepper(
                    "\(minutes) min",
                    value: Binding(get: { minutes }, set: { onChanged($0) }),
                    in: 1...60
                )
                .fixedSize()
            }
        } else {
            Button(action: onLocked) {
                HStack {
                    Text(label)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(minutes) min")
                        .foregroundStyle(.secondary)
                    ProBadge()
                }
            }
        }
    }
}

private struct SessionsPerCycleRow: View {
    let value: Int
    let isPremium: Bool
    let onChanged: (Int) -> Void
    let onLocked: () -> Void
    
    var body: some View {
        if isPremium {
            HStack {
                Text("Sessions per cycle")
                Spacer()
                Stepper(
                    "\(value) session\(value == 1 ? "" : "s")",
                    value: Binding(get: { value }, set: { onChanged($0) }),
                    in: 2...8
                )
                .fixedSize()
            }
        } else {
            Button(action: onLocked) {
                HStack {
                    Text("Sessions per cycle")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(value) session\(value == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                    ProBadge()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(TimerService())
        .environment(AudioManager())
        .environment(StoreManager())
}
