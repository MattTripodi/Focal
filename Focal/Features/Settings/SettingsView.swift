//
//  SettingsView.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(AudioManager.self) private var audio
    @State private var showingSoundPicker = false
    @Environment(StoreManager.self) private var store
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
        } header: {
            Text("Timer Durations")
        } footer: {
            if !store.isPremium {
                Text("Custom durations are available with Focal Premium.")
            }
        }
    }


    // MARK: - Behavior (Premium)

    private var behaviorSection: some View {
        Section("Behavior") {
            HStack {
                Text("Auto-start next session")
                Spacer()
                if !store.isPremium { ProLabel() }
                Toggle("", isOn: store.isPremium
                    ? Binding(
                        get: { timerService.autoStartNextSession },
                        set: { timerService.autoStartNextSession = $0 }
                    )
                    : .constant(false)
                )
                .labelsHidden()
                .disabled(!store.isPremium)
            }
            .contentShape(Rectangle())
            .onTapGesture { if !store.isPremium { showingPaywall = true } }
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
            }
        }
    }
}

// MARK: - Subviews

private struct DurationRow: View {
    let label: String
    let minutes: Int
    let isPremium: Bool
    let onChanged: (Int) -> Void
    let onLocked: () -> Void

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if isPremium {
                Stepper("\(minutes) min", value: Binding(
                    get: { minutes },
                    set: { onChanged($0) }
                ), in: 1...60)
                .fixedSize()
            } else {
                Text("\(minutes) min").foregroundStyle(.secondary)
                ProLabel()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if !isPremium { onLocked() } }
    }
}

private struct ProLabel: View {
    var body: some View {
        Text("PRO")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(Color.secondary.opacity(0.4)))
    }
}

private struct SoundPickerSheet: View {
    let audio: AudioManager
    let isPremium: Bool
    let onUpgradeTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ambient Sound")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 16)

            ForEach(AudioManager.Sound.allCases) { sound in
                Button {
                    if sound.isPremium && !isPremium {
                        onUpgradeTapped()
                    } else if sound == audio.currentSound {
                        audio.stop()
                    } else {
                        audio.play(sound)
                    }
                } label: {
                    HStack {
                        Image(systemName: sound.systemImage).frame(width: 28)
                        Text(sound.rawValue)
                        Spacer()
                        if sound.isPremium && !isPremium {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(Capsule().stroke(Color.secondary.opacity(0.4)))
                        }
                        if sound == audio.currentSound {
                            Image(systemName: "checkmark").foregroundStyle(.primary)
                        }
                    }
                    .foregroundStyle(sound.isPremium && !isPremium ? .secondary : .primary)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
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
