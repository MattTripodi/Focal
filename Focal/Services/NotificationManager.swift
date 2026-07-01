//
//  NotificationManager.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import Foundation
import UserNotifications
import Observation

@Observable
@MainActor
final class NotificationManager: NSObject {

    private(set) var isAuthorized = false

    override init() {
        super.init()
        // Set delegate so notifications show while app is foregrounded
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermissionIfNeeded() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                isAuthorized = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound])
            } catch {
                print("[Notifications] Permission request failed: \(error)")
            }
        case .authorized, .provisional:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    func schedule(for phase: TimerService.Phase, in seconds: TimeInterval) {
        guard isAuthorized else { return }
        cancelPending()

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch phase {
        case .work:
            content.title = "Focus session complete"
            content.body = "Time for a break. Good work."
        case .shortBreak:
            content.title = "Break's over"
            content.body = "Ready to focus again?"
        case .longBreak:
            content.title = "Long break complete"
            content.body = "Back to it when you're ready."
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "focal.phase-end",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[Notifications] Schedule failed: \(error)")
            }
        }
    }

    func cancelPending() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["focal.phase-end"])
    }
}

// MARK: - Foreground Presentation

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banner + play sound even when app is in the foreground
        return [.banner, .sound]
    }
}
