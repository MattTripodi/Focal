//
//  StatsView.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var sessions: [FocusSession]
    @State private var viewModel = StatsViewModel()
    @Environment(StoreManager.self) private var store
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    todayCard
                    weeklyCard
                    allTimeCard
                }
                .padding()
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { viewModel.update(with: sessions) }
        .onChange(of: sessions) { _, new in viewModel.update(with: new) }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environment(store)
        }
    }

    // MARK: - Today (Free)

    private var todayCard: some View {
        StatCard(title: "Today") {
            HStack(spacing: 0) {
                StatTile(value: "\(viewModel.todayCount)",   label: "Sessions")
                Divider().frame(height: 44)
                StatTile(value: "\(viewModel.todayMinutes)", label: "Minutes")
            }
        }
    }

    // MARK: - Weekly (Premium)

    private var weeklyCard: some View {
        StatCard(title: "This Week", isPremium: !store.isPremium) {
            WeeklyBarChart(data: viewModel.weeklyData)
                .frame(height: 80)
                .blur(radius: store.isPremium ? 0 : 4)
                .overlay { if !store.isPremium { LockOverlay() } }
                .onTapGesture { if !store.isPremium { showingPaywall = true } }
        }
    }

    // MARK: - All Time (Premium)

    private var allTimeCard: some View {
        StatCard(title: "All Time", isPremium: !store.isPremium) {
            HStack(spacing: 0) {
                StatTile(value: "\(viewModel.totalSessions)", label: "Total Sessions")
                Divider().frame(height: 44)
                StatTile(value: "\(viewModel.currentStreak)", label: "Day Streak")
            }
            .blur(radius: store.isPremium ? 0 : 4)
            .overlay { if !store.isPremium { LockOverlay() } }
            .onTapGesture { if !store.isPremium { showingPaywall = true } }
        }
    }
}

// MARK: - Supporting Views

private struct StatCard<Content: View>: View {
    let title: String
    var isPremium: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                if isPremium { ProBadge() }
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .thin, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WeeklyBarChart: View {
    let data: [(label: String, count: Int)]
    private var maxCount: Int { max(data.map(\.count).max() ?? 1, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.label) { day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary)
                        .frame(height: max(4, CGFloat(day.count) / CGFloat(maxCount) * 60))
                    Text(day.label)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct LockOverlay: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "lock.fill").font(.caption)
            Text("Unlock Premium").font(.caption).fontWeight(.medium)
        }
        .foregroundStyle(.primary)
    }
}

#Preview {
    StatsView()
        .environment(StoreManager())
        .modelContainer(ModelContainer.focal)
}
