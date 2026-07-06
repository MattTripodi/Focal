//
//  AppEnvironment.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/30/26.
//

import Foundation
import Observation

/// Owns and wires all app-level services.
/// Injected into the SwiftUI environment from FocalApp.
@Observable
@MainActor
final class AppEnvironment {

    let timerService        = TimerService()
    let notificationManager = NotificationManager()
    let audioManager        = AudioManager()
    let storeManager = StoreManager()

    init() {
        wireCallbacks()
    }

    private func wireCallbacks() {
        // Schedule a notification whenever the timer starts running
        timerService.onTimerStarted = { [weak self] phase, duration in
            guard let self else { return }
            notificationManager.schedule(for: phase, in: duration)
        }

        // Cancel pending notification on pause, reset, or skip
        timerService.onTimerPausedOrReset = { [weak self] in
            self?.notificationManager.cancelPending()
        }

        timerService.onWidgetNeedsUpdate = { [weak self] in
            guard let self else { return }
            WidgetDataManager.shared.update(from: timerService)
        }
    }
}
