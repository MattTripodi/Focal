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
            SoundPickerSheet(audio: audio)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Timer Durations (Premium)

    private var timerSection: some View {
        Section {
            DurationRow(label: "Work",        minutes: Int(timerService.workDuration / 60))
            DurationRow(label: "Short Break", minutes: Int(timerService.shortBreakDuration / 60))
            DurationRow(label: "Long Break",  minutes: Int(timerService.longBreakDuration / 60))
        } header: {
            Text("Timer Durations")
        } footer: {
            Text("Custom durations are available with Focal Premium.")
        }
    }

    // MARK: - Behavior (Premium)

    private var behaviorSection: some View {
        Section("Behavior") {
            HStack {
                Text("Auto-start next session")
                Spacer()
                ProLabel()
                Toggle("", isOn: .constant(false))
                    .labelsHidden()
                    .disabled(true)
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
            }
        }
    }
}

// MARK: - Subviews

private struct DurationRow: View {
    let label: String
    let minutes: Int

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(minutes) min").foregroundStyle(.secondary)
            ProLabel()
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ambient Sound")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 16)

            ForEach(AudioManager.Sound.allCases) { sound in
                Button {
                    sound == audio.currentSound ? audio.stop() : audio.play(sound)
                } label: {
                    HStack {
                        Image(systemName: sound.systemImage).frame(width: 28)
                        Text(sound.rawValue)
                        Spacer()
                        if sound.isPremium {
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
                    .foregroundStyle(sound.isPremium ? .secondary : .primary)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(sound.isPremium)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(TimerService())
        .environment(AudioManager())
}
