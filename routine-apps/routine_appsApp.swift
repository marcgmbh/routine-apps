//
//  routine_appsApp.swift
//  routine-apps
//
//  Created by marc on 09.08.25.
//

import SwiftUI
import SwiftData

@main
struct routine_appsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedContainer)
    }
}

private let sharedContainer: ModelContainer = {
    do {
        let schema = Schema([Routine.self, RoutineStep.self])
        let config = ModelConfiguration(schema: schema)
        return try ModelContainer(for: schema, configurations: config)
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }
}()
