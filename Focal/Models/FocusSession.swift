//
//  FocusSession.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/12/26.
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var startDate: Date
    var duration: TimeInterval  // seconds
    var phase: String           // "work" | "shortBreak" | "longBreak"
    var completed: Bool

    init(
        startDate: Date = .now,
        duration: TimeInterval,
        phase: String,
        completed: Bool = true
    ) {
        self.startDate = startDate
        self.duration = duration
        self.phase = phase
        self.completed = completed
    }
}
