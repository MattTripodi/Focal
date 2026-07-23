//
//  WidgetTimerData.swift
//  Focal
//
//  Created by Matthew Tripodi on 7/5/26.
//

import Foundation

struct WidgetTimerData: Codable {
    var phase: String
    var isRunning: Bool
    var timeRemaining: TimeInterval
    var phaseDuration: TimeInterval = 25 * 60  // default prevents decode failure on old cache
    var endDate: Date?
    var sessionsToday: Int
    var currentCycleRounds: Int
    var sessionsPerCycle: Int

    static let userDefaultsKey = "focal.widgetData"

    static var placeholder: WidgetTimerData {
        WidgetTimerData(
            phase: "Focus",
            isRunning: false,
            timeRemaining: 25 * 60,
            phaseDuration: 25 * 60,
            endDate: nil,
            sessionsToday: 0,
            currentCycleRounds: 0,
            sessionsPerCycle: 4
        )
    }

    var timeRemainingFormatted: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
