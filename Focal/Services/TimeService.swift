//
//  TimeService.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/27/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class TimerService {

    // MARK: - Types

    enum Phase: String {
        case work       = "Focus"
        case shortBreak = "Short Break"
        case longBreak  = "Long Break"

        var systemImage: String {
            switch self {
            case .work:        return "brain.head.profile"
            case .shortBreak:  return "cup.and.saucer"
            case .longBreak:   return "sofa"
            }
        }
    }

    enum TimerState {
        case idle, running, paused
    }

    // MARK: - Observable State

    private(set) var phase: Phase = .work
    private(set) var timerState: TimerState = .idle
    private(set) var timeRemaining: TimeInterval = 25 * 60

    /// How many work sessions completed in the current 4-round cycle.
    private(set) var currentCycleRounds: Int = 0

    /// Running total of work sessions completed today.
    private(set) var completedSessionsToday: Int = 0

    // MARK: - Settings (premium will override these later)

    var workDuration: TimeInterval      = 25 * 60
    var shortBreakDuration: TimeInterval = 5 * 60
    var longBreakDuration: TimeInterval  = 15 * 60
    let sessionsPerCycle: Int = 4

    // MARK: - Callbacks

    /// Fires when a work session completes naturally. Wire to SwiftData save on Day 2.
    var onPhaseComplete: ((Phase) -> Void)?

    // MARK: - Private

    private var timerTask: Task<Void, Never>?

    // MARK: - Computed

    var progress: Double {
        let total = currentPhaseDuration
        guard total > 0 else { return 0 }
        return 1.0 - (timeRemaining / total)
    }

    var timeRemainingFormatted: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var currentPhaseDuration: TimeInterval {
        switch phase {
        case .work:        return workDuration
        case .shortBreak:  return shortBreakDuration
        case .longBreak:   return longBreakDuration
        }
    }

    // MARK: - Public Interface

    func start() {
        guard timerState != .running else { return }
        timerState = .running
        startTicking()
    }

    func pause() {
        guard timerState == .running else { return }
        timerState = .paused
        timerTask?.cancel()
        timerTask = nil
    }

    func reset() {
        timerTask?.cancel()
        timerTask = nil
        timerState = .idle
        timeRemaining = currentPhaseDuration
    }

    /// Skips the current phase without counting it as a completed session.
    func skip() {
        advancePhase(sessionCompleted: false)
    }

    // MARK: - Private

    private func startTicking() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }

                if timeRemaining > 1 {
                    timeRemaining -= 1
                } else {
                    timeRemaining = 0
                    advancePhase(sessionCompleted: true)
                    break
                }
            }
        }
    }

    private func advancePhase(sessionCompleted: Bool) {
        timerTask?.cancel()
        timerTask = nil

        let completedPhase = phase

        if sessionCompleted && completedPhase == .work {
            currentCycleRounds += 1
            completedSessionsToday += 1
            onPhaseComplete?(.work)
        }

        // Determine next phase
        switch completedPhase {
        case .work:
            phase = currentCycleRounds >= sessionsPerCycle ? .longBreak : .shortBreak
        case .shortBreak:
            phase = .work
        case .longBreak:
            currentCycleRounds = 0
            phase = .work
        }

        timeRemaining = currentPhaseDuration
        timerState = .idle
    }
}
