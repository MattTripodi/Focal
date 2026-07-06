//
//  PaywallView.swift
//  Focal
//
//  Created by Matthew Tripodi on 7/5/26.
//

import SwiftUI

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 44))
                    .padding(.bottom, 4)

                Text("Focal Premium")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Unlock the full experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 48)
            .padding(.bottom, 40)

            // Feature list
            VStack(alignment: .leading, spacing: 18) {
                FeatureRow(icon: "slider.horizontal.3",
                           title: "Custom durations",
                           detail: "Set your own work and break lengths")
                FeatureRow(icon: "speaker.wave.2",
                           title: "Ambient sounds",
                           detail: "White noise, café, forest, ocean")
                FeatureRow(icon: "chart.bar",
                           title: "Full stats & streaks",
                           detail: "Weekly history and all-time totals")
                FeatureRow(icon: "rectangle.stack",
                           title: "Home screen widget",
                           detail: "See your timer and sessions at a glance")
                FeatureRow(icon: "arrow.clockwise",
                           title: "Auto-start sessions",
                           detail: "Keep the momentum going automatically")
            }
            .padding(.horizontal, 32)

            Spacer()

            // Purchase controls
            VStack(spacing: 12) {
                if let error = store.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await store.purchase() }
                } label: {
                    ZStack {
                        if store.isLoading {
                            ProgressView().tint(Color(uiColor: .systemBackground))
                        } else {
                            Text("Unlock for \(store.premiumPrice)")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primary)
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(store.isLoading)

                Button("Restore Purchases") {
                    Task { await store.restorePurchases() }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 24)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.medium)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}
