//
//  TimerService.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/27/26.
//

import Foundation
import Observation
import UIKit

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
    
    var workDuration: TimeInterval = {
        let v = UserDefaults.standard.double(forKey: "focal.workDuration")
        return v > 0 ? v : 25 * 60
    }() {
        didSet { UserDefaults.standard.set(workDuration, forKey: "focal.workDuration") }
    }
    
    var shortBreakDuration: TimeInterval = {
        let v = UserDefaults.standard.double(forKey: "focal.shortBreakDuration")
        return v > 0 ? v : 5 * 60
    }() {
        didSet { UserDefaults.standard.set(shortBreakDuration, forKey: "focal.shortBreakDuration") }
    }
    
    var longBreakDuration: TimeInterval = {
        let v = UserDefaults.standard.double(forKey: "focal.longBreakDuration")
        return v > 0 ? v : 15 * 60
    }() {
        didSet { UserDefaults.standard.set(longBreakDuration, forKey: "focal.longBreakDuration") }
    }
    
    // Add after longBreakDuration:
    var autoStartNextSession: Bool = UserDefaults.standard.bool(forKey: "focal.autoStart") {
        didSet { UserDefaults.standard.set(autoStartNextSession, forKey: "focal.autoStart") }
    }
    
    var sessionsPerCycle: Int = {
        let v = UserDefaults.standard.integer(forKey: "focal.sessionsPerCycle")
        return v > 0 ? v : 4
    }() {
        didSet {
            UserDefaults.standard.set(sessionsPerCycle, forKey: "focal.sessionsPerCycle")
            // If current rounds exceed the new cycle length, clamp to avoid
            // being stuck in a state that never triggers a long break
            if currentCycleRounds >= sessionsPerCycle {
                currentCycleRounds = sessionsPerCycle - 1
            }
            // Notify widget immediately so dot count reflects the change
            // without requiring a timer interaction
            onWidgetNeedsUpdate?()
        }
    }
    
    // MARK: - Callbacks
    
    /// Fires when a work session completes naturally. Wire to SwiftData save on Day 2.
    var onPhaseComplete: ((Phase) -> Void)?
    
    /// Fires when the timer starts running. Use to schedule a notification.
    var onTimerStarted: ((Phase, TimeInterval) -> Void)?
    
    /// Fires on pause, reset, or skip. Use to cancel pending notifications.
    var onTimerPausedOrReset: (() -> Void)?
    
    /// Fires on any state change that the widget should reflect.
    var onWidgetNeedsUpdate: (() -> Void)?
    
    // MARK: - Private
    
    private var timerTask: Task<Void, Never>?
    private var endDate: Date?
    
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
    
    var currentPhaseDuration: TimeInterval {
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
        endDate = Date.now.addingTimeInterval(timeRemaining)
        onTimerStarted?(phase, timeRemaining)
        onWidgetNeedsUpdate?()
        startTicking()
    }
    
    func pause() {
        guard timerState == .running else { return }
        timerState = .paused
        timerTask?.cancel()
        timerTask = nil
        endDate = nil
        onTimerPausedOrReset?()
        onWidgetNeedsUpdate?()
    }
    
    func reset() {
        timerTask?.cancel()
        timerTask = nil
        timerState = .idle
        endDate = nil
        timeRemaining = currentPhaseDuration
        onTimerPausedOrReset?()
        onWidgetNeedsUpdate?()
    }
    
    /// Skips the current phase without counting it as a completed session.
    func skip() {
        onTimerPausedOrReset?()
        advancePhase(sessionCompleted: false)
    }
    
    // MARK: - Private
    
    private func startTicking() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                
                guard let end = endDate else { break }
                let remaining = end.timeIntervalSinceNow
                
                if remaining > 0.5 {
                    // Round for clean display — eliminates fractional second flicker
                    timeRemaining = remaining.rounded()
                } else {
                    timeRemaining = 0
                    try? await Task.sleep(for: .milliseconds(1100))
                    guard !Task.isCancelled else { break }
                    advancePhase(sessionCompleted: true)
                    break
                }
            }
        }
    }
    
    private func advancePhase(sessionCompleted: Bool) {
        timerTask?.cancel()
        timerTask = nil
        endDate = nil
        
        let completedPhase = phase
        
        // Haptic feedback on phase completion
        let haptic = UINotificationFeedbackGenerator()
        if sessionCompleted {
            haptic.notificationOccurred(completedPhase == .work ? .success : .warning)
        }
        
        if sessionCompleted && completedPhase == .work {
            currentCycleRounds += 1
            completedSessionsToday += 1
            onPhaseComplete?(.work)
        }
        
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
        onWidgetNeedsUpdate?()
        
        if autoStartNextSession {
            start()
        }
    }
}

// MARK: - Debug / Screenshot Staging

#if DEBUG
extension TimerService {
    
    func stageForScreenshot(_ scenario: ScreenshotScenario) {
        timerTask?.cancel()
        timerTask = nil
        
        switch scenario {
            
        case .timerRunning:
            phase              = .work
            timeRemaining      = 18 * 60 + 32
            currentCycleRounds = 2
            timerState         = .running
            startTicking()
            
        case .timerIdleThreeDots:
            phase              = .work
            timeRemaining      = workDuration
            currentCycleRounds = 3
            timerState         = .idle
            
        case .reset:
            phase              = .work
            timeRemaining      = workDuration
            currentCycleRounds = 0
            timerState         = .idle
        }
    }
    
    enum ScreenshotScenario {
        case timerRunning
        case timerIdleThreeDots
        case reset
    }
}
#endif
