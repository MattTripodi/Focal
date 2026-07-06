//
//  FocalWidget.swift
//  FocalWidget
//
//  Created by Matthew Tripodi on 6/12/26.
//

import WidgetKit
import SwiftUI

// MARK: - Entry

struct FocalWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetTimerData
}

// MARK: - Provider

struct FocalWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> FocalWidgetEntry {
        FocalWidgetEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocalWidgetEntry) -> Void) {
        completion(FocalWidgetEntry(date: .now, data: storedData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocalWidgetEntry>) -> Void) {
        let entry = FocalWidgetEntry(date: .now, data: storedData())
        // Refresh at most every 15 min; app triggers reloads on state changes
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func storedData() -> WidgetTimerData {
        guard
            let defaults = UserDefaults(suiteName: "group.com.matthewtripodi.focal"),
            let raw = defaults.data(forKey: WidgetTimerData.userDefaultsKey),
            let data = try? JSONDecoder().decode(WidgetTimerData.self, from: raw)
        else {
            return .placeholder
        }
        return data
    }
}

// MARK: - View

struct FocalWidgetEntryView: View {
    let entry: FocalWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            // Phase label
            Text(entry.data.phase.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(.secondary)

            // Timer — live countdown when running, static otherwise
            Group {
                if entry.data.isRunning,
                   let endDate = entry.data.endDate,
                   endDate > entry.date {
                    Text(timerInterval: entry.date...endDate, countsDown: true)
                        .monospacedDigit()
                } else {
                    Text(entry.data.timeRemainingFormatted)
                        .monospacedDigit()
                }
            }
            .font(.system(size: 30, weight: .thin, design: .monospaced))
            .minimumScaleFactor(0.6)
            .lineLimit(1)

            Spacer()

            // Cycle dots
            HStack(spacing: 5) {
                ForEach(0..<entry.data.sessionsPerCycle, id: \.self) { i in
                    Circle()
                        .fill(
                            i < entry.data.currentCycleRounds
                                ? Color.primary
                                : Color.primary.opacity(0.15)
                        )
                        .frame(width: 5, height: 5)
                }
            }

            // Sessions today
            Text("\(entry.data.sessionsToday) session\(entry.data.sessionsToday == 1 ? "" : "s") today")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(Color(uiColor: .systemBackground), for: .widget)
        .widgetURL(URL(string: "focal://open"))
    }
}

// MARK: - Widget

struct FocalWidget: Widget {
    let kind = "FocalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocalWidgetProvider()) { entry in
            FocalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focal Timer")
        .description("Track your focus sessions at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    FocalWidget()
} timeline: {
    FocalWidgetEntry(date: .now, data: .placeholder)
    FocalWidgetEntry(date: .now, data: WidgetTimerData(
        phase: "Focus",
        isRunning: true,
        timeRemaining: 18 * 60,
        endDate: Date.now.addingTimeInterval(18 * 60),
        sessionsToday: 2,
        currentCycleRounds: 2,
        sessionsPerCycle: 4
    ))
}
