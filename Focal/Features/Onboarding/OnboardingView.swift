//
//  OnboardingView.swift
//  Focal
//
//  Created by Matthew Tripodi on 7/6/26.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Deep work, simplified",
            body: "Focal uses the Pomodoro method to help you focus in short, effective bursts with built-in breaks."
        ),
        OnboardingPage(
            icon: "bell",
            title: "Never lose track",
            body: "Get notified the moment a session or break ends — whether the app is open or not."
        ),
        OnboardingPage(
            icon: "speaker.wave.2",
            title: "Set the mood",
            body: "Ambient sounds like rain and white noise help you get into flow and stay there."
        ),
        OnboardingPage(
            icon: "chart.bar",
            title: "Watch the streak grow",
            body: "Track your sessions and build daily focus habits over time."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack(spacing: 16) {
                // Dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.primary : Color.primary.opacity(0.2))
                            .frame(width: 6, height: 6)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }

                // CTA
                Button {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Skip
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        hasCompletedOnboarding = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                    Color.clear.frame(height: 20)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: page.icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.primary)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
