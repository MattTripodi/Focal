//
//  ModelContainer+Focal.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/28/26.
//

import Foundation
import SwiftData

extension ModelContainer {
    @MainActor
    static let focal: ModelContainer = {
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.matthewtripodi.focal") else {
            fatalError("App Group container not found — check entitlements.")
        }

        let config = ModelConfiguration(
            url: groupURL.appendingPathComponent("focal.store")
        )

        do {
            return try ModelContainer(for: FocusSession.self, configurations: config)
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()
}
