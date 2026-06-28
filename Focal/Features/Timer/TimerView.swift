//
//  TimerView.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/27/26.
//

import SwiftUI

struct TimerView: View {
    @Environment(TimerService.self) private var timer

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

// MARK: - Preview

#Preview {
    TimerView()
        .environment(TimerService())
}
