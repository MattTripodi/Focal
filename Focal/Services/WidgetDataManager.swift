//
//  WidgetDataManager.swift
//  Focal
//
//  Created by Matthew Tripodi on 7/5/26.
//

import Foundation
import WidgetKit

@MainActor
final class WidgetDataManager {
    static let shared = WidgetDataManager()

    // Must match your App Group identifier
    private let suiteName = "group.com.matthewtripodi.focal"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private init() {}

    func update(from timer: TimerService) {
        let endDate: Date? = timer.timerState == .running
            ? Date.now.addingTimeInterval(timer.timeRemaining)
            : nil

        let data = WidgetTimerData(
            phase: timer.phase.rawValue,
            isRunning: timer.timerState == .running,
            timeRemaining: timer.timeRemaining,
            phaseDuration: timer.currentPhaseDuration,
            endDate: endDate,
            sessionsToday: timer.completedSessionsToday,
            currentCycleRounds: timer.currentCycleRounds,
            sessionsPerCycle: timer.sessionsPerCycle
        )

        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults?.set(encoded, forKey: WidgetTimerData.userDefaultsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
