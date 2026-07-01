//
//  StatsViewModel.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class StatsViewModel {

    private(set) var todayCount: Int = 0
    private(set) var todayMinutes: Int = 0
    private(set) var totalSessions: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var weeklyData: [(label: String, count: Int)] = []

    func update(with sessions: [FocusSession]) {
        let work = sessions.filter { $0.phase == "Focus" && $0.completed }
        let calendar = Calendar.current

        // Today
        let todays = work.filter { calendar.isDateInToday($0.startDate) }
        todayCount   = todays.count
        todayMinutes = todays.reduce(0) { $0 + Int($1.duration) } / 60

        // All time
        totalSessions = work.count

        // Streak — counts consecutive days backwards from today
        currentStreak = streak(from: work, calendar: calendar)

        // Last 7 days for weekly chart
        let dayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        weeklyData = (0..<7).reversed().compactMap { offset -> (String, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { return nil }
            let count   = work.filter { calendar.isDate($0.startDate, inSameDayAs: date) }.count
            let weekday = calendar.component(.weekday, from: date)
            return (dayLabels[weekday - 1], count)
        }
    }

    private func streak(from sessions: [FocusSession], calendar: Calendar) -> Int {
        guard !sessions.isEmpty else { return 0 }
        var count = 0
        var date  = Date.now
        while sessions.contains(where: { calendar.isDate($0.startDate, inSameDayAs: date) }) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }
}
