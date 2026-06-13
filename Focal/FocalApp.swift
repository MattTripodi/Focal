//
//  FocalApp.swift
//  Focal
//
//  Created by Matthew Tripodi on 6/12/26.
//

import SwiftUI
import SwiftData

@main
struct FocalApp: App {
    
    let container: ModelContainer
    
    init() {
        // Use the App Group container URL so FocalWidget can read sessions
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.matthewtripodi.focal") else {
            fatalError("App Group container URL not found — check your entitlements.")
        }
        
        let storeURL = groupURL.appendingPathComponent("focal.store")
        
        let config = ModelConfiguration(url: storeURL)
        
        do {
            container = try ModelContainer(for: FocusSession.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TimerView()
        }
        .modelContainer(container)
    }
}
