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

// MARK: - Root View (routes by family)

struct FocalWidgetEntryView: View {
    let entry: FocalWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small (Home Screen)

struct SmallWidgetView: View {
    let entry: FocalWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.data.phase.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(.secondary)

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

// MARK: - Circular (Lock Screen)

struct CircularWidgetView: View {
    let entry: FocalWidgetEntry

    private var progress: Double {
        guard entry.data.phaseDuration > 0 else { return 0 }
        return 1.0 - (entry.data.timeRemaining / entry.data.phaseDuration)
    }

    var body: some View {
        Gauge(value: progress) {
            EmptyView()
        } currentValueLabel: {
            if entry.data.isRunning,
               let endDate = entry.data.endDate,
               endDate > entry.date {
                Text(timerInterval: entry.date...endDate, countsDown: true)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .minimumScaleFactor(0.4)
                    .monospacedDigit()
            } else {
                Text(entry.data.timeRemainingFormatted)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .minimumScaleFactor(0.4)
                    .monospacedDigit()
            }
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(.clear, for: .widget)
        .widgetURL(URL(string: "focal://open"))
    }
}

// MARK: - Rectangular (Lock Screen)

struct RectangularWidgetView: View {
    let entry: FocalWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.data.phase.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(.secondary)

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
            .font(.system(size: 26, weight: .thin, design: .monospaced))
            .minimumScaleFactor(0.6)
            .lineLimit(1)

            Text("\(entry.data.sessionsToday) session\(entry.data.sessionsToday == 1 ? "" : "s") today")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.clear, for: .widget)
        .widgetURL(URL(string: "focal://open"))
    }
}

// MARK: - Widget + Bundle

struct FocalWidget: Widget {
    let kind = "FocalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocalWidgetProvider()) { entry in
            FocalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focal Timer")
        .description("Track your focus sessions at a glance.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    FocalWidget()
} timeline: {
    FocalWidgetEntry(date: .now, data: .placeholder)
}

#Preview(as: .accessoryCircular) {
    FocalWidget()
} timeline: {
    FocalWidgetEntry(date: .now, data: WidgetTimerData(
        phase: "Focus",
        isRunning: true,
        timeRemaining: 18 * 60,
        phaseDuration: 25 * 60,
        endDate: Date.now.addingTimeInterval(18 * 60),
        sessionsToday: 2,
        currentCycleRounds: 2,
        sessionsPerCycle: 4
    ))
}

#Preview(as: .accessoryRectangular) {
    FocalWidget()
} timeline: {
    FocalWidgetEntry(date: .now, data: WidgetTimerData(
        phase: "Focus",
        isRunning: true,
        timeRemaining: 18 * 60,
        phaseDuration: 25 * 60,
        endDate: Date.now.addingTimeInterval(18 * 60),
        sessionsToday: 2,
        currentCycleRounds: 2,
        sessionsPerCycle: 4
    ))
}
