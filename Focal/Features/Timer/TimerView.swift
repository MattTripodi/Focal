//
//  TimerView.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/27/26.
//

import SwiftUI

struct TimerView: View {
    @Environment(TimerService.self) private var timer
    @Environment(AudioManager.self) private var audio
    @State private var showingSoundPicker = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Phase label
            Text(timer.phase.rawValue.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .kerning(2)
                .foregroundStyle(.secondary)

            Spacer().frame(height: 40)

            // Timer ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timer.progress)

                VStack(spacing: 6) {
                    Text(timer.timeRemainingFormatted)
                        .font(.system(size: 58, weight: .thin, design: .monospaced))
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Image(systemName: timer.phase.systemImage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 270, height: 270)

            Spacer().frame(height: 40)

            // Cycle dots
            CycleDotsView(
                completed: timer.currentCycleRounds,
                total: timer.sessionsPerCycle
            )

            Spacer()

            // Controls
            HStack(spacing: 44) {
                TimerControlButton(systemImage: "arrow.counterclockwise", size: .secondary) {
                    timer.reset()
                }
                .opacity(timer.timerState == .idle ? 0.2 : 1)
                .disabled(timer.timerState == .idle)

                TimerControlButton(
                    systemImage: timer.timerState == .running ? "pause.fill" : "play.fill",
                    size: .primary
                ) {
                    timer.timerState == .running ? timer.pause() : timer.start()
                }

                TimerControlButton(systemImage: "forward.end.fill", size: .secondary) {
                    timer.skip()
                }
            }
            
            Spacer()
            
            // Sound picker button
            Button {
                showingSoundPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: audio.currentSound.systemImage)
                    Text(audio.currentSound.rawValue)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.secondary.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingSoundPicker) {
                SoundPickerSheet(audio: audio)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
            }

            Spacer().frame(height: 52)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Cycle Dots

private struct CycleDotsView: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < completed ? Color.primary : Color.primary.opacity(0.12))
                    .frame(width: 7, height: 7)
                    .animation(.spring(duration: 0.3), value: completed)
            }
        }
    }
}

// MARK: - Control Button

private enum ControlSize {
    case primary, secondary

    var frame: CGFloat  { self == .primary ? 72 : 48 }
    var iconFont: Font  { self == .primary ? .title2 : .body }
}

private struct TimerControlButton: View {
    let systemImage: String
    let size: ControlSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if size == .primary {
                Image(systemName: systemImage)
                    .font(size.iconFont)
                    .frame(width: size.frame, height: size.frame)
                    .background(Color.primary, in: Circle())
                    .foregroundStyle(Color(uiColor: .systemBackground))
            } else {
                Image(systemName: systemImage)
                    .font(size.iconFont)
                    .frame(width: size.frame, height: size.frame)
                    .foregroundStyle(Color.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sound Picker Sheet

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
                // Premium sounds are visible but disabled until Day 4 paywall
                Button {
                    if sound == audio.currentSound {
                        audio.stop()
                    } else {
                        audio.play(sound)
                    }
                } label: {
                    HStack {
                        Image(systemName: sound.systemImage)
                            .frame(width: 28)
                        Text(sound.rawValue)
                        Spacer()
                        if sound.isPremium {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(
                                    Capsule().stroke(Color.secondary.opacity(0.4))
                                )
                        }
                        if sound == audio.currentSound {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.primary)
                        }
                    }
                    .foregroundStyle(sound.isPremium ? .secondary : .primary)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(sound.isPremium) // gates open on Day 4
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TimerView()
        .environment(TimerService())
}
